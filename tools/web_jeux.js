// (E8) Les jeux dans le build Web, dans un Chromium sans écran (Playwright), à la main, hors de
// tools/check.sh (docs/web.md, raccourci ?jeu=) :
//
//   tools/godot --headless --export-release Web build/web/index.html
//   python3 -m http.server 8347 --bind 127.0.0.1 --directory build/web &
//   NODE_PATH=/opt/node-tools/node_modules node tools/web_jeux.js http://127.0.0.1:8347/index.html build/shots [ballon|baton…]
//
// Pour chaque jeu, un profil neuf ouvre index.html?trace&jeu=<jeu> : menu, clic, Entrée (nouvelle
// partie), puis le raccourci de test pose la partie sur l'entrepôt et lance le jeu (« [m1] jeu
// lancé »). La page compte ses images (requestAnimationFrame) sur MEASURE_MS : images par seconde,
// image la plus longue ; draw calls du journal ([m1]), moyenne et maximum. Capture jeux_web_<jeu>.png.
// Le rendu logiciel (SwiftShader) est lent : les images/s ne valent que pour comparer, les draw calls
// sont ceux du navigateur.
const { chromium } = require('playwright');

const BASE = process.argv[2] || 'http://127.0.0.1:8347/index.html';
const SHOTS = process.argv[3] || 'build/shots';
const GAMES = process.argv.length > 4 ? process.argv.slice(4) : ['ballon', 'baton'];
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

async function measure(browser, game) {
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
	await page.goto(`${BASE}?trace&jeu=${game}`);
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
	const launched = await waitLog(logs, /jeu lancé|jeu inconnu/, 240000);
	if (launched < 0) {
		console.log(`${game} : le jeu n'a pas démarré`);
		await context.close();
		return problems;
	}
	await sleep(SETTLE_MS);
	await page.evaluate(() => {
		window.gameFrames = [];
		let last = performance.now();
		const tick = (now) => {
			window.gameFrames.push(now - last);
			last = now;
			requestAnimationFrame(tick);
		};
		requestAnimationFrame(tick);
	});
	const from = logs.length;
	await sleep(MEASURE_MS);
	const frames = await page.evaluate(() => window.gameFrames.slice(1));
	await page.screenshot({ path: `${SHOTS}/jeux_web_${game}.png` });
	const total = frames.reduce((s, v) => s + v, 0);
	const draws = logs.slice(from).map((l) => /\[m1\] (\d+) i\/s, (\d+) draw calls/.exec(l)).filter((m) => m);
	const drawMean = draws.reduce((s, m) => s + Number(m[2]), 0) / Math.max(draws.length, 1);
	console.log(
		`${game} : ${(frames.length / (total / 1000)).toFixed(2)} images/s, image la plus longue`
		+ ` ${Math.max(...frames, 0).toFixed(0)} ms sur ${frames.length} images ; ${drawMean.toFixed(0)} draw calls`
		+ ` (max ${Math.max(...draws.map((m) => Number(m[2])), 0)})`
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
	for (const game of GAMES) {
		problems.push(...(await measure(browser, game)));
	}
	console.log('--- erreurs et avertissements ---');
	for (const p of problems) {
		console.log(p);
	}
	await browser.close();
})();
