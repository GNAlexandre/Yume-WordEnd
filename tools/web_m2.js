// Vérification de l'acte 1 du build Web dans un Chromium sans écran (Playwright), à la main, hors
// de tools/check.sh (docs/web.md, « Vérification de l'acte 1 »).
//
//   tools/godot --headless --export-release Web build/web/index.html
//   python3 -m http.server 8347 --bind 127.0.0.1 --directory build/web &
//   NODE_PATH=/opt/node-tools/node_modules node tools/web_m2.js http://127.0.0.1:8347/index.html build/shots [acte1|zones|tout]
//
// acte1 (le début de l'acte 1, puis la reprise) :
// 1. index.html?trace=1 dans un profil neuf : temps jusqu'au menu (repère window.wordendMenuMs
//    posé par src/main.gd), clic « Cliquer pour jouer » (acte1_web_menu.png), Entrée sur
//    « Nouvelle partie », temps de chargement et images affichées pendant ce temps
//    (acte1_web_entrepot.png). Puis les premières étapes d'act1_main, à pied (Z/W tenue) : vers
//    Nygglatho sous le porche, E, sa scène lue à E (acte1_web_nygglatho.png ; étape new_officer),
//    vers Willem près de la salle des armes, sa scène (acte1_web_willem.png ; étape to_the_woods,
//    drapeau met_willem), puis par la porte nord jusqu'aux bois du marais (acte1_web_bois.png ;
//    étape rejetons). Le canevas perd alors le focus (SaveManager écrit la partie) ; attente de la
//    copie dans IndexedDB.
// 2. Page rechargée, même profil : clic (acte1_web_continue.png), Entrée sur « Continuer » : la
//    partie reprend dans les bois, à la même étape (journal « [m1] partie : zone …, étapes … »).
// zones (images par seconde de chaque zone) : index.html?zone=<id> dans un profil neuf pour
//    village, forest, dunes, beach et hill : nouvelle partie au Spawn de la zone, puis les
//    images affichées par la page (requestAnimationFrame) et les mesures « [m1] n i/s, draw
//    calls, primitives » des raccourcis de test pendant 20 s (acte1_web_zone_<id>.png).
// Le joueur se tourne vers sa cible par window.wordendFace(cible) (raccourcis de test,
// src/test_shortcuts.gd : un PNJ ou un point de l'île), qui la pose dans window.wordendAim ; il y
// marche aux touches, choisies d'après la caméra fixe HD-2D (le haut de l'écran est le nord). Le rendu
// logiciel (SwiftShader) tourne à 1 ou 2 images/s : les appuis sont tenus plus d'une image, et
// les images/s n'ont qu'une valeur indicative. Toutes les erreurs et tous les avertissements de
// la console sont relevés et imprimés à la fin.
const { chromium } = require('playwright');

const BASE = process.argv[2] || 'http://127.0.0.1:8347/index.html';
const SHOTS = process.argv[3] || 'build/shots';
const MODE = process.argv[4] || 'tout';
const VIEW = { width: 1280, height: 720 };
const ZONES = ['village', 'forest', 'dunes', 'beach', 'hill'];
const t0 = Date.now();

function sleep(ms) {
	return new Promise((r) => setTimeout(r, ms));
}

function stamp() {
	return `${((Date.now() - t0) / 1000).toFixed(1)}s`;
}

async function waitLog(logs, pattern, timeoutMs, from = 0) {
	const start = Date.now();
	while (Date.now() - start < timeoutMs) {
		if (logs.slice(from).some((l) => pattern.test(l))) {
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

// Touches tenues jusqu'à ce que predicate (éventuellement asynchrone) soit vrai (true) ou
// timeoutMs (false).
async function holdUntil(page, codes, predicate, timeoutMs) {
	for (const code of codes) {
		await page.keyboard.down(code);
	}
	const start = Date.now();
	let reached = false;
	while (Date.now() - start < timeoutMs) {
		if (await predicate()) {
			reached = true;
			break;
		}
		await sleep(100);
	}
	for (const code of codes) {
		await page.keyboard.up(code);
	}
	return reached;
}

// Position du joueur à l'image courante (window.wordendPos des raccourcis de test), sinon la
// dernière du journal.
async function position(page, logs) {
	const p = await page.evaluate(() => window.wordendPos || null);
	return p ? { x: p[0], z: p[1] } : lastPosition(logs);
}

// Tourne le joueur (caméra derrière lui) vers un PNJ ou un point (raccourcis de test).
async function face(page, logs, x, z) {
	const mark = logs.length;
	if (typeof x === 'string') {
		await page.evaluate((id) => window.wordendFace(id), x);
	} else {
		await page.evaluate(([a, b]) => window.wordendFace(a, b), [x, z]);
	}
	await waitLog(logs, /\[m1\] visée/, 10000, mark);
	await sleep(800);
}

// (HD-2D) Touches (W/A/S/D, une ou deux pour les diagonales) qui mènent du joueur vers la cible
// posée par wordendFace (window.wordendAim) : la caméra fixe regarde le nord, le haut de l'écran.
async function aimKeys(page, logs) {
	const aim = await page.evaluate(() => window.wordendAim || null);
	const p = await position(page, logs);
	if (!aim || !p) {
		return ['KeyW'];
	}
	const dx = aim[0] - p.x;
	const dz = aim[1] - p.z;
	const length = Math.hypot(dx, dz) || 1;
	const keys = [];
	if (dz < -0.38 * length) keys.push('KeyW');
	if (dz > 0.38 * length) keys.push('KeyS');
	if (dx > 0.38 * length) keys.push('KeyD');
	if (dx < -0.38 * length) keys.push('KeyA');
	return keys.length ? keys : ['KeyW'];
}

// Marche vers la cible de wordendFace jusqu'à predicate (true) ou timeoutMs (false) : les touches
// sont choisies de nouveau toutes les 300 ms, comme un joueur qui corrige sa route.
async function steerUntil(page, logs, predicate, timeoutMs) {
	let held = [];
	const start = Date.now();
	let reached = false;
	while (Date.now() - start < timeoutMs) {
		if (await predicate()) {
			reached = true;
			break;
		}
		const keys = await aimKeys(page, logs);
		for (const code of held.filter((k) => !keys.includes(k))) {
			await page.keyboard.up(code);
		}
		for (const code of keys.filter((k) => !held.includes(k))) {
			await page.keyboard.down(code);
		}
		held = keys;
		await sleep(300);
	}
	for (const code of held) {
		await page.keyboard.up(code);
	}
	return reached;
}

// Marche vers le point (x ; z) jusqu'à y arriver à tolerance m près (le long du trajet).
async function walkTo(page, logs, x, z, tolerance = 0.8, timeoutMs = 120000) {
	await face(page, logs, x, z);
	const from = await position(page, logs);
	const ok = await steerUntil(
		page,
		logs,
		async () => {
			const p = await position(page, logs);
			if (!p || !from) {
				return false;
			}
			const dx = x - from.x;
			const dz = z - from.z;
			const length = Math.hypot(dx, dz) || 1;
			const along = ((p.x - from.x) * dx + (p.z - from.z) * dz) / length;
			return along >= length - tolerance;
		},
		timeoutMs
	);
	console.log(`vers (${x} ; ${z}) :`, ok, await position(page, logs));
	return ok;
}

// Marche vers un PNJ jusqu'à son invite « Parler », puis lit sa scène à E jusqu'à la fin du
// dialogue ; capture shot à la première réplique. Renvoie les répliques affichées.
async function talkTo(page, logs, npcId, speaker, shot) {
	await face(page, logs, npcId);
	const mark = logs.length;
	const prompt = await steerUntil(
		page,
		logs,
		async () => logs.slice(mark).some((l) => /\[m1\] invite « Parler »/.test(l)),
		120000
	);
	console.log(`invite « Parler » devant ${npcId} :`, prompt, await position(page, logs));
	await sleep(1500);
	const started = logs.length;
	await tap(page, 'KeyE');
	const opened = await waitLog(logs, new RegExp(`\\[m1\\] dialogue ${speaker}`), 60000, started);
	console.log(`dialogue de ${speaker} :`, opened);
	await sleep(3000);
	await page.screenshot({ path: `${SHOTS}/${shot}` });
	const ended = new RegExp(`fin du dialogue \\(${npcId}\\)`);
	for (let i = 0; i < 30 && !logs.slice(started).some((l) => ended.test(l)); i++) {
		await tap(page, 'KeyE');
		await sleep(1200);
	}
	const lines = logs.slice(started).filter((l) => /\[m1\] dialogue /.test(l));
	console.log(`fin du dialogue (${npcId}) :`, logs.slice(started).some((l) => ended.test(l)));
	return lines;
}

// Sauvegarde telle que copiée dans IndexedDB (IDBFS de Godot, base « /userfs ») : { zone, x, z,
// step, saved_at }, ou null. C'est elle que la page relira au prochain chargement.
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
						const progress = (data.quest_progress || {}).act1_main || {};
						resolve({
							zone: data.zone,
							x: data.position[0],
							z: data.position[2],
							step: progress.step || '',
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
		if (/\[m1\]/.test(l) && !/i\/s, \d+ draw calls/.test(l)) {
			console.log(l);
		}
	}
}

// Menu (clic « Cliquer pour jouer »), puis Entrée : nouvelle partie ou Continuer.
async function enterGame(page, logs, menuShot) {
	const menuMs = await menuTime(page);
	console.log('temps jusqu\'au menu (ms, rendu logiciel) :', Math.round(menuMs));
	await sleep(2000);
	await page.mouse.click(VIEW.width / 2, VIEW.height / 2);
	await sleep(3000);
	if (menuShot) {
		await page.screenshot({ path: `${SHOTS}/${menuShot}` });
	}
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
	const frames = await page.evaluate(() => {
		window.m2Counting = false;
		return window.m2Frames;
	});
	console.log(
		'partie chargée :',
		loaded,
		`(${((Date.now() - askedAt) / 1000).toFixed(1)} s après Entrée, ${frames} images affichées)`
	);
	console.log(lastMatch(logs, /\[m1\] partie : .*/)?.[0]);
	return loaded;
}

async function firstAct(browser, problems) {
	const context = await browser.newContext({ viewport: VIEW });
	const page = await context.newPage();
	const logs = [];
	watch(page, logs, problems);

	// 1. Profil neuf : menu, nouvelle partie, l'entrepôt.
	await page.goto(`${BASE}?trace=1`);
	await enterGame(page, logs, 'acte1_web_menu.png');
	await waitLog(logs, /\[m1\] zone village/, 60000);
	await waitLog(logs, /position \(/, 30000);
	await sleep(3000);
	await page.screenshot({ path: `${SHOTS}/acte1_web_entrepot.png` });
	// Étape morning : Nygglatho sous le porche, par l'ouest de la place (loin de Tiat et des
	// lampadaires), puis tout droit au nord.
	await walkTo(page, logs, -9.3, 9);
	let lines = await talkTo(page, logs, 'nygglatho', 'Nygglatho', 'acte1_web_nygglatho.png');
	console.log('le grand vent :', lines.some((l) => /Le vent a hurlé/.test(l)));
	console.log('étape new_officer :', await waitLog(logs, /étape act1_main : new_officer/, 20000));
	// Étape new_officer : Willem, près de la porte de la salle des armes.
	await walkTo(page, logs, -8.5, -1);
	lines = await talkTo(page, logs, 'willem', 'Willem', 'acte1_web_willem.png');
	console.log('ses conseils :', lines.some((l) => /verrouille ta cible/.test(l)));
	console.log('étape to_the_woods :', await waitLog(logs, /étape act1_main : to_the_woods/, 20000));
	// Étape to_the_woods : par la porte nord, jusqu'aux bois du marais.
	await walkTo(page, logs, -4, -3);
	await walkTo(page, logs, 0, -12);
	await face(page, logs, 0, -60);
	const woods = await holdUntil(
		page,
		['KeyW'],
		() => logs.some((l) => /\[m1\] zone forest/.test(l)),
		180000
	);
	console.log('les bois du marais à pied :', woods, await position(page, logs));
	await tap(page, 'KeyW', 3000);
	console.log('étape rejetons :', await waitLog(logs, /étape act1_main : rejetons/, 20000));
	await sleep(3000);
	await page.screenshot({ path: `${SHOTS}/acte1_web_bois.png` });
	// L'onglet perd le focus : la partie est écrite, puis copiée dans IndexedDB à l'image suivante.
	await sleep(3000);
	const blurred = logs.length;
	await page.evaluate(() => document.getElementById('canvas').dispatchEvent(new FocusEvent('blur')));
	await waitLog(logs, /\[m1\] fenêtre sans focus/, 30000, blurred);
	const left = lastMatch(logs.slice(blurred), /\[m1\] fenêtre sans focus : .*/);
	console.log(left ? left[0] : 'pas de journal de perte du focus');
	const before = lastPosition(logs);
	console.log('position en quittant :', before);
	// Copie vers IndexedDB : immédiate avec un vrai GPU ; ici, le rendu logiciel occupe le fil
	// principal et la copie asynchrone attend parfois 30 s : on l'attend avant de recharger.
	const copyStart = Date.now();
	let copied = null;
	while (Date.now() - copyStart < 180000) {
		copied = await idbSave(page);
		const near = copied && before && Math.hypot(copied.x - before.x, copied.z - before.z) < 0.5;
		if (near && copied.step === 'rejetons') {
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
	const resumed = await enterGame(page, logs2, 'acte1_web_continue.png');
	const start = lastMatch(logs2, /\[m1\] partie : zone « (\w*) », position \((-?[\d.]+) ; (-?[\d.]+)\)/);
	console.log('partie reprise :', resumed);
	if (start && before) {
		const dx = parseFloat(start[2]) - before.x;
		const dz = parseFloat(start[3]) - before.z;
		console.log('zone :', start[1], '; écart de position (m) :', Math.hypot(dx, dz).toFixed(2));
	}
	console.log('reprise à l\'étape rejetons :', lastMatch(logs2, /rejetons/) !== null);
	await sleep(3000);
	dump('journal après rechargement', logs2);
	await context.close();
}

// Images par seconde, draw calls et primitives d'une zone (mesures « [m1] » des raccourcis).
async function measureZone(browser, zone, problems) {
	const context = await browser.newContext({ viewport: VIEW });
	const page = await context.newPage();
	const logs = [];
	watch(page, logs, problems);
	await page.goto(`${BASE}?zone=${zone}`);
	await enterGame(page, logs, null);
	await waitLog(logs, new RegExp(`\\[m1\\] zone ${zone}`), 60000);
	// Images affichées par la page pendant la mesure (requestAnimationFrame : une par image du
	// moteur quand il est plus lent que l'écran), en plus des mesures « [m1] » du moteur.
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
	const mark = logs.length;
	const start = Date.now();
	await sleep(20000);
	const frames = await page.evaluate(() => {
		window.m2Counting = false;
		return window.m2Frames;
	});
	const pageFps = (frames / ((Date.now() - start) / 1000)).toFixed(2);
	await page.screenshot({ path: `${SHOTS}/acte1_web_zone_${zone}.png` });
	const samples = logs
		.slice(mark)
		.map((l) => /\[m1\] (\d+) i\/s, (\d+) draw calls, (\d+) primitives/.exec(l))
		.filter((m) => m)
		.map((m) => ({ fps: +m[1], calls: +m[2], prims: +m[3] }));
	await context.close();
	if (samples.length === 0) {
		return { zone, pageFps, samples: 0 };
	}
	const mean = (key) => samples.reduce((s, v) => s + v[key], 0) / samples.length;
	return {
		zone,
		pageFps,
		samples: samples.length,
		fps: mean('fps').toFixed(1),
		calls: Math.round(mean('calls')),
		prims: Math.round(mean('prims')),
	};
}

(async () => {
	const browser = await chromium.launch({
		headless: true,
		args: ['--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
	});
	const problems = [];
	if (MODE === 'acte1' || MODE === 'tout') {
		await firstAct(browser, problems);
	}
	if (MODE === 'zones' || MODE === 'tout') {
		console.log('--- images par seconde par zone (rendu logiciel, indicatif) ---');
		for (const zone of ZONES) {
			const r = await measureZone(browser, zone, problems);
			console.log(JSON.stringify(r));
		}
	}
	console.log('--- erreurs et avertissements de la console ---');
	console.log(problems.length ? problems.join('\n') : '(aucun)');
	await browser.close();
})();
