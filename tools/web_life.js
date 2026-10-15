// (E4) La vie dans le build Web, dans un Chromium sans écran (Playwright), à la main, hors de
// tools/check.sh (docs/web.md, « La vie ») :
//
//   tools/godot --headless --export-release Web build/web/index.html
//   python3 -m http.server 8347 --bind 127.0.0.1 --directory build/web &
//   NODE_PATH=/opt/node-tools/node_modules node tools/web_life.js http://127.0.0.1:8347/index.html build/shots [mode…]
//
// Pour chaque mode (défaut : off on cycle), un profil neuf ouvre
// index.html?trace&maps=entrepot_rdc_essai&moment=matin&creneau=matin&vie=<mode> : menu, clic,
// Entrée (nouvelle partie), puis les raccourcis de test (src/test_shortcuts.gd) vont au
// rez-de-chaussée d'essai, où LifeDirector pose les quinze PNJ du petit-déjeuner. Modes : off (le
// directeur coupé : la mesure « avant »), on (?vie=trace : les PNJ vivent, le directeur écrit ses
// coûts toutes les 2 s : « [vie] … directeur … ms/image (max …), navigation …, chemins … »),
// cycle (en plus, le créneau suivant toutes les 20 s : les PNJ marchent, la navigation et les
// chemins travaillent). La page compte ses images (requestAnimationFrame) sur MEASURE_MS : images
// par seconde, image la plus longue, part des images au-delà de 25 ms et de 50 ms ; draw calls
// du journal ([m1]). Capture life_web_<mode>.png. Le rendu logiciel (SwiftShader) est lent : les
// images/s et les durées d'image valent pour comparer les modes entre eux, pas dans l'absolu ; le
// coût du directeur ([vie]) se lit, lui, en millisecondes de calcul.
const { chromium } = require('playwright');

const BASE = process.argv[2] || 'http://127.0.0.1:8347/index.html';
const SHOTS = process.argv[3] || 'build/shots';
const MODES = process.argv.length > 4 ? process.argv.slice(4) : ['off', 'on', 'cycle'];
const VIEW = { width: 1280, height: 720 };
const SETTLE_MS = 8000;
const MEASURE_MS = 45000;
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

async function measure(browser, mode) {
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
	const life = mode === 'on' ? 'trace' : mode;
	await page.goto(`${BASE}?trace&maps=entrepot_rdc_essai&moment=matin&creneau=matin&contenu=essai&vie=${life}`);
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
	const arrived = await waitLog(logs, /carte entrepot_rdc_essai chargée/, 240000);
	if (arrived < 0) {
		console.log(`${mode} : pas arrivé au rez-de-chaussée d'essai`);
		await context.close();
		return problems;
	}
	await sleep(SETTLE_MS);
	await page.evaluate(() => {
		window.lifeFrames = [];
		let last = performance.now();
		const tick = (now) => {
			window.lifeFrames.push(now - last);
			last = now;
			requestAnimationFrame(tick);
		};
		requestAnimationFrame(tick);
	});
	const from = logs.length;
	await sleep(MEASURE_MS);
	const frames = await page.evaluate(() => window.lifeFrames.slice(1));
	await page.screenshot({ path: `${SHOTS}/life_web_${mode}.png` });
	const total = frames.reduce((s, v) => s + v, 0);
	const over = (ms) => frames.filter((v) => v > ms).length;
	const sorted = [...frames].sort((a, b) => a - b);
	const p95 = sorted[Math.floor(sorted.length * 0.95)] || 0;
	const draws = logs.slice(from).map((l) => /\[m1\] (\d+) i\/s, (\d+) draw calls/.exec(l)).filter((m) => m);
	const drawMean = draws.reduce((s, m) => s + Number(m[2]), 0) / Math.max(draws.length, 1);
	console.log(
		`${mode} : ${(frames.length / (total / 1000)).toFixed(2)} images/s, image la plus longue`
		+ ` ${Math.max(...frames, 0).toFixed(0)} ms, 95 % sous ${p95.toFixed(0)} ms, ${over(25)} images`
		+ ` > 25 ms et ${over(50)} > 50 ms sur ${frames.length} ; ${drawMean.toFixed(0)} draw calls`
		+ ` (max ${Math.max(...draws.map((m) => Number(m[2])), 0)})`
	);
	for (const line of logs.slice(from).filter((l) => /\[vie\]/.test(l))) {
		console.log(`  ${line}`);
	}
	await context.close();
	return problems;
}

(async () => {
	const browser = await chromium.launch({
		headless: true,
		args: ['--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
	});
	const problems = [];
	for (const mode of MODES) {
		problems.push(...(await measure(browser, mode)));
	}
	console.log('--- erreurs et avertissements ---');
	for (const p of problems) {
		console.log(p);
	}
	await browser.close();
})();
