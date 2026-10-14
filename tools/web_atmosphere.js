// (E9) Lumière et temps dans le build Web, dans un Chromium sans écran (Playwright), à la main,
// hors de tools/check.sh (docs/web.md, « Lumière et temps ») :
//
//   tools/godot --headless --export-release Web build/web/index.html
//   python3 -m http.server 8347 --bind 127.0.0.1 --directory build/web &
//   NODE_PATH=/opt/node-tools/node_modules node tools/web_atmosphere.js http://127.0.0.1:8347/index.html build/shots [moment:temps …]
//
// Pour chaque préréglage (défaut : couchant:clair nuit:clair couchant:pluie nuit:averse
// matin:clair), un profil neuf ouvre index.html?trace&moment=<moment>&temps=<temps> : menu, clic,
// Entrée (nouvelle partie au Spawn du village, sous ce préréglage, posé par Atmosphere), puis les
// lignes « [m1] <n> i/s, <d> draw calls … » des raccourcis de test (src/test_shortcuts.gd,
// toutes les 2 s) donnent les draw calls, moyennés sur REPORTS lignes une fois la partie posée,
// et les images affichées par la page sont comptées sur MEASURE_MS (images/s à deux décimales) ; capture atmosphere_web_<moment>_<temps>.png. Le rendu logiciel
// (SwiftShader) est lent : les images/s valent pour comparer les préréglages entre eux et avec le
// build d'avant (sans paramètre, le couchant), pas dans l'absolu. Erreurs et avertissements de la
// console à la fin.
const { chromium } = require('playwright');

const BASE = process.argv[2] || 'http://127.0.0.1:8347/index.html';
const SHOTS = process.argv[3] || 'build/shots';
const PRESETS = process.argv.length > 4
	? process.argv.slice(4)
	: ['couchant:clair', 'nuit:clair', 'couchant:pluie', 'nuit:averse', 'matin:clair'];
const VIEW = { width: 1280, height: 720 };
const REPORTS = 4;
const SETTLE_MS = 6000;
// Images affichées par la page (requestAnimationFrame) comptées sur au moins MEASURE_MS (le temps
// de lire REPORTS lignes du journal, s'il est plus long) : plus fin que les images/s entières du
// journal quand le rendu logiciel tourne à une image par seconde.
const MEASURE_MS = 30000;
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

async function measure(browser, preset) {
	const [moment, weather] = preset.split(':');
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
	await page.goto(`${BASE}?trace&moment=${moment}&temps=${weather}`);
	await waitLog(logs, /Godot Engine v4\.7/, 90000);
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
	await page.keyboard.down('Enter');
	await sleep(300);
	await page.keyboard.up('Enter');
	const started = await waitLog(logs, /\[m1\] partie : zone/, 240000);
	if (started < 0) {
		console.log(`${preset} : pas de partie`);
		await context.close();
		return problems;
	}
	await sleep(SETTLE_MS);
	await page.evaluate(() => {
		window.atmosphereFrames = 0;
		const tick = () => {
			window.atmosphereFrames++;
			requestAnimationFrame(tick);
		};
		requestAnimationFrame(tick);
	});
	const measuredFrom = Date.now();
	const from = logs.length;
	const pattern = /\[m1\] (\d+) i\/s, (\d+) draw calls, (\d+) primitives/;
	const deadline = Date.now() + 120000;
	let found = [];
	while (found.length < REPORTS && Date.now() < deadline) {
		found = logs.slice(from).map((l) => pattern.exec(l)).filter((m) => m !== null);
		await sleep(250);
	}
	const rest = MEASURE_MS - (Date.now() - measuredFrom);
	if (rest > 0) {
		await sleep(rest);
	}
	const frames = await page.evaluate(() => window.atmosphereFrames);
	const seconds = (Date.now() - measuredFrom) / 1000;
	const rate = frames / seconds;
	await page.screenshot({ path: `${SHOTS}/atmosphere_web_${moment}_${weather}.png` });
	const mean = (k) => found.reduce((s, m) => s + Number(m[k]), 0) / Math.max(found.length, 1);
	const draws = found.map((m) => Number(m[2]));
	console.log(
		`${preset} : ${rate.toFixed(2)} images/s (page, ${frames} en ${seconds.toFixed(0)} s ;`
		+ ` journal ${mean(1).toFixed(1)} i/s), ${mean(2).toFixed(0)} draw calls (max ${Math.max(...draws, 0)}),`
		+ ` ${mean(3).toFixed(0)} primitives, ${found.length} relevés`
	);
	await context.close();
	return problems;
}

(async () => {
	const browser = await chromium.launch({
		headless: true,
		args: ['--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
	});
	const problems = [];
	for (const preset of PRESETS) {
		problems.push(...(await measure(browser, preset)));
	}
	console.log('--- erreurs et avertissements ---');
	for (const p of problems) {
		console.log(p);
	}
	await browser.close();
})();
