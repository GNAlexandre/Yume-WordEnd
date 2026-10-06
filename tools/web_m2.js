// Vérification M2 du build Web dans un Chromium sans écran (Playwright), à la main, hors de
// tools/check.sh (docs/web.md, « Vérification M2 »).
//
//   tools/godot --headless --export-release Web build/web/index.html
//   python3 -m http.server 8347 --bind 127.0.0.1 --directory build/web &
//   NODE_PATH=/opt/node-tools/node_modules node tools/web_m2.js http://127.0.0.1:8347/index.html build/shots
//
// 1. index.html?trace=1 dans un profil neuf : temps jusqu'au menu (repère window.wordendMenuMs
//    posé par src/main.gd), clic « Cliquer pour jouer » (m2_web_menu.png), Entrée sur « Nouvelle
//    partie », temps de chargement de la partie et images affichées pendant ce temps
//    (m2_web_village.png) ; Z/W puis Q/A tenues jusqu'à l'invite « Parler » de la
//    bibliothécaire, E (m2_web_dialogue.png quand elle pose sa question), lecture à E et quête
//    acceptée ; quelques pas en arrière, puis le canevas perd le focus (SaveManager écrit la
//    position aussitôt) ; attente de la copie de la sauvegarde dans IndexedDB.
// 2. Page rechargée, même profil (IndexedDB) : clic (m2_web_continue.png), Entrée sur
//    « Continuer » ; la partie reprend à la position quittée (journal « [m1] partie : zone …,
//    position (x ; z), quêtes …, objets … »).
// Le paramètre trace des raccourcis de test (src/test_shortcuts.gd) ne change rien à la partie :
// il écrit le journal « [m1] … » qui permet de la suivre. Le rendu logiciel (SwiftShader) tourne à
// 1 ou 2 images/s : les appuis sont tenus plus d'une image. Toutes les erreurs et tous les
// avertissements de la console sont relevés et imprimés à la fin (aucun attendu).
const { chromium } = require('playwright');

const BASE = process.argv[2] || 'http://127.0.0.1:8347/index.html';
const SHOTS = process.argv[3] || 'build/shots';
const VIEW = { width: 1280, height: 720 };
const t0 = Date.now();

function sleep(ms) {
	return new Promise((r) => setTimeout(r, ms));
}

function stamp() {
	return `${((Date.now() - t0) / 1000).toFixed(1)}s`;
}

async function waitLog(logs, pattern, timeoutMs) {
	const start = Date.now();
	while (Date.now() - start < timeoutMs) {
		if (logs.some((l) => pattern.test(l))) {
			return true;
		}
		await sleep(200);
	}
	return false;
}

function lastMatch(logs, pattern) {
	for (let i = logs.length - 1; i >= 0; i--) {
		const m = pattern.exec(logs[i]);
		if (m) {
			return m;
		}
	}
	return null;
}

// Dernière position du joueur relevée dans le journal, ou null.
function lastPosition(logs) {
	const m = lastMatch(logs, /position \((-?[\d.]+) ; (-?[\d.]+)\)/);
	return m ? { x: parseFloat(m[1]), z: parseFloat(m[2]) } : null;
}

// Appui tenu plus d'une image (à 1 image/s, un appui bref peut tomber entre deux images).
async function tap(page, code, ms = 1200) {
	await page.keyboard.down(code);
	await sleep(ms);
	await page.keyboard.up(code);
}

// Touches tenues jusqu'à ce que predicate soit vrai (true) ou timeoutMs (false).
async function holdUntil(page, codes, predicate, timeoutMs) {
	for (const code of codes) {
		await page.keyboard.down(code);
	}
	const start = Date.now();
	let reached = false;
	while (Date.now() - start < timeoutMs) {
		if (predicate()) {
			reached = true;
			break;
		}
		await sleep(150);
	}
	for (const code of codes) {
		await page.keyboard.up(code);
	}
	return reached;
}

// Sauvegarde telle que copiée dans IndexedDB (IDBFS de Godot, base « /userfs ») : { zone, x, z,
// saved_at }, ou null. C'est elle que la page relira au prochain chargement.
async function idbSave(page) {
	return page.evaluate(
		() =>
			new Promise((resolve) => {
				const request = indexedDB.open('/userfs');
				request.onerror = () => resolve(null);
				request.onsuccess = () => {
					const db = request.result;
					const store = db.transaction(['FILE_DATA'], 'readonly').objectStore('FILE_DATA');
					const get = store.get('/userfs/godot/app_userdata/WordEnd/save_v1.json');
					get.onsuccess = () => {
						db.close();
						const value = get.result;
						if (!value || !value.contents) {
							resolve(null);
							return;
						}
						const data = JSON.parse(new TextDecoder().decode(value.contents));
						resolve({
							zone: data.zone,
							x: data.position[0],
							z: data.position[2],
							saved_at: data.saved_at,
						});
					};
					get.onerror = () => {
						db.close();
						resolve(null);
					};
				};
			})
	);
}

async function menuTime(page) {
	const start = Date.now();
	while (Date.now() - start < 90000) {
		const ms = await page.evaluate(() => window.wordendMenuMs || 0);
		if (ms > 0) {
			return ms;
		}
		await sleep(250);
	}
	return -1;
}

function watch(page, logs, problems) {
	page.on('console', (m) => {
		const line = `${stamp()} [${m.type()}] ${m.text()}`;
		logs.push(line);
		if (m.type() === 'error' || m.type() === 'warning') {
			problems.push(line);
		}
	});
	page.on('pageerror', (e) => problems.push(`${stamp()} [pageerror] ${e.message}`));
}

function dump(title, logs) {
	console.log(`--- ${title} ---`);
	for (const l of logs) {
		if (/\[m1\]/.test(l)) {
			console.log(l);
		}
	}
}

(async () => {
	const browser = await chromium.launch({
		headless: true,
		args: ['--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
	});
	const context = await browser.newContext({ viewport: VIEW });
	const page = await context.newPage();
	const logs = [];
	const problems = [];
	watch(page, logs, problems);

	// 1. Profil neuf : menu, nouvelle partie, bibliothécaire.
	await page.goto(`${BASE}?trace=1`);
	const menuMs = await menuTime(page);
	console.log('temps jusqu\'au menu (ms, rendu logiciel) :', Math.round(menuMs));
	await sleep(2000);
	await page.mouse.click(VIEW.width / 2, VIEW.height / 2);
	await sleep(3000);
	await page.screenshot({ path: `${SHOTS}/m2_web_menu.png` });
	// Images affichées pendant le chargement (requestAnimationFrame) : Loading.load_scene rend la
	// main au navigateur entre deux paquets de dépendances, la page ne se fige pas.
	await page.evaluate(() => {
		window.m2Frames = 0;
		window.m2Counting = true;
		const tick = () => {
			window.m2Frames++;
			if (window.m2Counting) {
				requestAnimationFrame(tick);
			}
		};
		requestAnimationFrame(tick);
	});
	const askedAt = Date.now();
	await tap(page, 'Enter', 300);
	const loaded = await waitLog(logs, /\[m1\] partie : zone/, 180000);
	const loadingFrames = await page.evaluate(() => {
		window.m2Counting = false;
		return window.m2Frames;
	});
	console.log(
		'partie chargée :',
		loaded,
		`(${((Date.now() - askedAt) / 1000).toFixed(1)} s après Entrée, ${loadingFrames} images affichées)`
	);
	console.log(lastMatch(logs, /\[m1\] partie : .*/)?.[0]);
	await waitLog(logs, /\[m1\] zone village/, 60000);
	await sleep(4000);
	await page.screenshot({ path: `${SHOTS}/m2_web_village.png` });
	// Vers la bibliothécaire (−3,5 ; 4) : tout droit vers la place jusqu'à z = 5, puis à gauche
	// jusqu'à son invite (l'enfant, plus à l'ouest, reste plus loin).
	const north = await holdUntil(page, ['KeyW'], () => (lastPosition(logs)?.z ?? 99) <= 5.2, 120000);
	console.log('au nord de la place :', north, lastPosition(logs));
	const mark = logs.length;
	const prompt = await holdUntil(
		page,
		['KeyA'],
		() => logs.slice(mark).some((l) => /\[m1\] invite « Parler »/.test(l)),
		120000
	);
	console.log('invite « Parler » :', prompt);
	await sleep(1500);
	await tap(page, 'KeyE');
	console.log('dialogue :', await waitLog(logs, /\[m1\] dialogue Biblioth/, 60000));
	let shot = false;
	for (let i = 0; i < 14 && !logs.some((l) => /fin du dialogue/.test(l)); i++) {
		if (!shot && logs.some((l) => /Je m’en occupe/.test(l))) {
			await sleep(2500);
			await page.screenshot({ path: `${SHOTS}/m2_web_dialogue.png` });
			shot = true;
		}
		await tap(page, 'KeyE');
		await sleep(1500);
	}
	console.log('quête acceptée :', logs.some((l) => /quête pages : active/.test(l)));
	console.log('fin du dialogue :', logs.some((l) => /fin du dialogue/.test(l)));
	// Quelques pas en arrière, puis l'onglet perd le focus : la position est écrite (journal
	// « fenêtre sans focus … (sauvegardée) »), puis copiée dans IndexedDB à l'image suivante.
	await tap(page, 'KeyS', 2500);
	await sleep(5000);
	const blurred = logs.length;
	await page.evaluate(() => document.getElementById('canvas').dispatchEvent(new FocusEvent('blur')));
	await waitLog(logs, /\[m1\] fenêtre sans focus/, 30000);
	const left = lastMatch(logs.slice(blurred), /\[m1\] fenêtre sans focus : .*/);
	console.log(left ? left[0] : 'pas de journal de perte du focus');
	const before = lastPosition(logs);
	console.log('position en quittant :', before);
	// Copie vers IndexedDB : immédiate avec un vrai GPU ; ici, le rendu logiciel occupe le fil
	// principal (1 image/s) et la copie asynchrone attend parfois 30 s : on l'attend avant de
	// recharger, sinon la page relirait la copie précédente.
	const copyStart = Date.now();
	let copied = null;
	while (Date.now() - copyStart < 180000) {
		copied = await idbSave(page);
		if (copied && before && Math.hypot(copied.x - before.x, copied.z - before.z) < 0.2) {
			break;
		}
		await sleep(2000);
	}
	console.log(
		`sauvegarde dans IndexedDB après ${((Date.now() - copyStart) / 1000).toFixed(0)} s :`,
		JSON.stringify(copied)
	);
	dump('journal de la première visite', logs);

	// 2. Page rechargée : Continuer.
	const logs2 = [];
	watch(page, logs2, []);
	await page.reload();
	const menuMs2 = await menuTime(page);
	console.log('temps jusqu\'au menu au rechargement (ms) :', Math.round(menuMs2));
	await sleep(2000);
	await page.mouse.click(VIEW.width / 2, VIEW.height / 2);
	await sleep(3000);
	await page.screenshot({ path: `${SHOTS}/m2_web_continue.png` });
	await tap(page, 'Enter');
	const resumed = await waitLog(logs2, /\[m1\] partie : zone/, 180000);
	const start = lastMatch(logs2, /\[m1\] partie : zone « (\w*) », position \((-?[\d.]+) ; (-?[\d.]+)\)/);
	console.log('partie reprise :', resumed, lastMatch(logs2, /\[m1\] partie : .*/)?.[0]);
	if (start && before) {
		const dx = parseFloat(start[2]) - before.x;
		const dz = parseFloat(start[3]) - before.z;
		console.log('écart de position (m) :', Math.hypot(dx, dz).toFixed(2));
	}
	await sleep(3000);
	dump('journal après rechargement', logs2);
	console.log('--- erreurs et avertissements de la console ---');
	console.log(problems.length ? problems.join('\n') : '(aucun)');
	await browser.close();
})();
