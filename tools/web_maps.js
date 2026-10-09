// (E1) Changements de carte du build Web dans un Chromium sans écran (Playwright), à la main,
// hors de tools/check.sh (docs/web.md, « Cartes : temps de chargement ») :
//
//   tools/godot --headless --export-release Web build/web/index.html
//   python3 -m http.server 8347 --bind 127.0.0.1 --directory build/web &
//   NODE_PATH=/opt/node-tools/node_modules node tools/web_maps.js http://127.0.0.1:8347/index.html build/shots [aller-retours]
//
// index.html?maps=essai,ile_ancienne,… dans un profil neuf : menu, clic, Entrée (nouvelle partie,
// la carte de départ chargée avec la partie par l'écran de chargement), puis les raccourcis de
// test (src/test_shortcuts.gd) font le voyage de carte en carte (WorldManager.go_to) et
// impriment une ligne de mesures par changement : « [m1] carte <id> chargée : fondu … ms,
// chargement … ms en n images, installation … ms, total … ms ». Les images affichées par la page
// pendant chaque changement sont comptées (requestAnimationFrame) : le chargement découpé rend
// la main au navigateur. Captures maps_web_<n>_<carte>.png à chaque arrivée. Le rendu logiciel
// (SwiftShader) est lent : les durées valent pour comparer, pas dans l'absolu. Toutes les erreurs
// et tous les avertissements de la console sont imprimés à la fin.
const { chromium } = require('playwright');

const BASE = process.argv[2] || 'http://127.0.0.1:8347/index.html';
const SHOTS = process.argv[3] || 'build/shots';
const ROUNDS = parseInt(process.argv[4] || '2', 10);
const VIEW = { width: 1280, height: 720 };
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
		const index = logs.slice(from).findIndex((l) => pattern.test(l));
		if (index >= 0) {
			return from + index;
		}
		await sleep(100);
	}
	return -1;
}

(async () => {
	const maps = [];
	for (let i = 0; i < ROUNDS; i++) {
		maps.push('essai', 'ile_ancienne');
	}
	const browser = await chromium.launch({
		headless: true,
		args: ['--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
	});
	const context = await browser.newContext({ viewport: VIEW });
	const page = await context.newPage();
	const logs = [];
	const problems = [];
	page.on('console', (m) => {
		const line = `${stamp()} [${m.type()}] ${m.text()}`;
		logs.push(line);
		if (m.type() === 'error' || m.type() === 'warning') {
			problems.push(line);
		}
	});
	page.on('pageerror', (e) => problems.push(`${stamp()} [pageerror] ${e.message}`));
	await page.goto(`${BASE}?maps=${maps.join(',')}`);
	console.log('moteur démarré :', (await waitLog(logs, /Godot Engine v4\.7/, 90000)) >= 0);
	const menuStart = Date.now();
	while (Date.now() - menuStart < 90000) {
		if (await page.evaluate(() => window.wordendMenuMs || 0)) {
			break;
		}
		await sleep(250);
	}
	await sleep(2000);
	await page.mouse.click(VIEW.width / 2, VIEW.height / 2);
	await sleep(3000);
	// Images affichées par la page, comptées en continu (requestAnimationFrame).
	await page.evaluate(() => {
		window.mapsFrames = 0;
		const tick = () => {
			window.mapsFrames++;
			requestAnimationFrame(tick);
		};
		requestAnimationFrame(tick);
	});
	const askedAt = Date.now();
	await page.keyboard.down('Enter');
	await sleep(300);
	await page.keyboard.up('Enter');
	const started = await waitLog(logs, /\[m1\] partie : zone/, 240000);
	console.log(
		'partie chargée (écran de chargement : partie et carte de départ) :',
		started >= 0,
		`${((Date.now() - askedAt) / 1000).toFixed(1)} s après Entrée`
	);
	let from = started >= 0 ? started : 0;
	for (let i = 0; i < maps.length; i++) {
		const leaving = await page.evaluate(() => window.mapsFrames);
		const begin = Date.now();
		const done = await waitLog(logs, new RegExp(`\\[m1\\] carte ${maps[i]} chargée`), 240000, from);
		const frames = (await page.evaluate(() => window.mapsFrames)) - leaving;
		if (done < 0) {
			console.log(`carte ${maps[i]} : pas d'arrivée`);
			break;
		}
		console.log(logs[done]);
		console.log(`  ${frames} images affichées par la page en ${((Date.now() - begin) / 1000).toFixed(1)} s`);
		// Le rendu logiciel tourne à 1 ou 2 images/s : la fin du fondu met plusieurs secondes à paraître.
		await sleep(4000);
		await page.screenshot({ path: `${SHOTS}/maps_web_${i}_${maps[i]}.png` });
		from = done + 1;
	}
	console.log('voyage terminé :', (await waitLog(logs, /\[m1\] voyage terminé/, 180000)) >= 0);
	const fps = logs.filter((l) => /\[m1\] \d+ i\/s/.test(l)).slice(-3);
	for (const l of fps) {
		console.log(l);
	}
	console.log('--- erreurs et avertissements ---');
	for (const p of problems) {
		console.log(p);
	}
	await browser.close();
})();
