// Vérification M1 du build Web dans un Chromium sans écran (Playwright), à la main, hors de
// tools/check.sh (docs/web.md, « Raccourcis de test et vérification M1 »).
//
//   tools/godot --headless --export-release Web build/web/index.html
//   python3 -m http.server 8347 --bind 127.0.0.1 --directory build/web &
//   NODE_PATH=/opt/node-tools/node_modules node tools/web_m1.js http://127.0.0.1:8347/index.html build/shots
//
// 1. index.html?zone=dunes : menu → Nouvelle partie → entrée des dunes ; marche jusqu'au panneau
//    (invite « Affronter les Timeres »), E, vague 1 ; quand un Timere approche, verrouillage et
//    coups d'épée, une capture par coup (m1_web_0..9.png) ; puis mort et réapparition au village
//    (m1_web_respawn.png) ; images/s mesurées par requestAnimationFrame.
// 2. index.html?zone=dunes&timeres=12 : banc de 12 Timeres (m1_web_bench.png), images/s.
// Tout est piloté par le journal « [m1] … » des raccourcis de test (src/test_shortcuts.gd) : le
// rendu logiciel (SwiftShader) tombe à 1 ou 2 images/s, les appuis sont donc tenus plus d'une
// image. Le journal filtré (lignes [m1] et erreurs) est imprimé à la fin : aucune erreur attendue.
const { chromium } = require('playwright');

const BASE = process.argv[2] || 'http://127.0.0.1:8347/index.html';
const SHOTS = process.argv[3] || 'build/shots';
const VIEW = { width: 800, height: 450 };
const t0 = Date.now();

function sleep(ms) {
	return new Promise((r) => setTimeout(r, ms));
}

function seen(logs, pattern) {
	return logs.some((l) => pattern.test(l));
}

async function waitLog(logs, pattern, timeoutMs) {
	const start = Date.now();
	while (Date.now() - start < timeoutMs) {
		if (seen(logs, pattern)) {
			return true;
		}
		await sleep(200);
	}
	return false;
}

// Distance du Timere le plus proche, d'après le dernier rapport « [m1] … le plus proche à X m ».
function nearest(logs) {
	for (let i = logs.length - 1; i >= 0; i--) {
		const m = /le plus proche à ([\d.]+) m/.exec(logs[i]);
		if (m) {
			return parseFloat(m[1]);
		}
	}
	return 999;
}

// Appui tenu plus d'une image (à 1 image/s, un appui bref peut tomber entre deux images).
async function tap(page, code, ms = 1300) {
	await page.keyboard.down(code);
	await sleep(ms);
	await page.keyboard.up(code);
}

async function fps(page, ms) {
	return page.evaluate(
		(duration) =>
			new Promise((resolve) => {
				let frames = 0;
				const start = performance.now();
				function tick(now) {
					frames++;
					if (now - start < duration) {
						requestAnimationFrame(tick);
					} else {
						resolve((frames * 1000) / (now - start));
					}
				}
				requestAnimationFrame(tick);
			}),
		ms
	);
}

async function open(browser, query, logs) {
	const page = await browser.newPage({ viewport: VIEW });
	page.on('console', (m) => logs.push(`${((Date.now() - t0) / 1000).toFixed(1)}s [${m.type()}] ${m.text()}`));
	page.on('pageerror', (e) => logs.push(`[pageerror] ${e.message}`));
	await page.goto(BASE + query);
	console.log('moteur démarré :', await waitLog(logs, /Godot Engine v4\.7/, 60000));
	await sleep(3000);
	// Menu : « Nouvelle partie » au centre (le bouton a aussi le focus clavier).
	await page.mouse.click(VIEW.width / 2, VIEW.height / 2 + 40);
	if (!(await waitLog(logs, /\[m1\] raccourcis/, 8000))) {
		await page.keyboard.press('Enter');
	}
	console.log('partie aux dunes :', await waitLog(logs, /\[m1\] zone dunes/, 90000));
	return page;
}

function dump(title, logs) {
	console.log(`--- ${title} ---`);
	for (const l of logs) {
		if (/\[m1\]|error|pageerror/i.test(l)) {
			console.log(l);
		}
	}
}

(async () => {
	const browser = await chromium.launch({
		headless: true,
		args: ['--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
	});
	// 1. Nouvelle partie → arène → vague qui démarre → combat → mort → village.
	const logs = [];
	const page = await open(browser, '?zone=dunes', logs);
	await page.keyboard.down('KeyW');
	const prompt = await waitLog(logs, /\[m1\] invite « Affronter les Timeres »/, 180000);
	await page.keyboard.up('KeyW');
	console.log('panneau atteint :', prompt);
	await tap(page, 'KeyE');
	console.log('vague 1 lancée :', await waitLog(logs, /\[m1\] vague 1 \(dunes\) : 5 Timeres/, 120000));
	// Un pas de côté (nord) : le panneau sort de l'axe de la caméra.
	await tap(page, 'KeyD', 2500);
	const start = Date.now();
	while (nearest(logs) > 3.5 && Date.now() - start < 240000) {
		await sleep(500);
	}
	console.log('Timere à moins de 3,5 m :', nearest(logs) <= 3.5);
	// Verrou sur le plus proche (clic molette) ; une capture par coup d'épée.
	await page.mouse.click(VIEW.width / 2, VIEW.height / 2, { button: 'middle' });
	for (let i = 0; i < 10; i++) {
		await page.keyboard.down('KeyJ');
		await sleep(600);
		await page.screenshot({ path: `${SHOTS}/m1_web_${i}.png` });
		await page.keyboard.up('KeyJ');
		await sleep(500);
	}
	console.log('Timere tué :', seen(logs, /\[m1\] timere_\w+ tué/));
	console.log('images/s (rAF, combat) :', (await fps(page, 5000)).toFixed(2));
	const back = await waitLog(logs, /\[m1\] joueur réapparu/, 180000);
	console.log('mort puis réapparition :', back);
	if (back) {
		await sleep(6000);
		await page.screenshot({ path: `${SHOTS}/m1_web_respawn.png` });
	}
	dump('journal de la partie', logs);
	await page.close();
	// 2. Banc de 12 Timeres devant le joueur.
	const benchLogs = [];
	const bench = await open(browser, '?zone=dunes&timeres=12', benchLogs);
	await sleep(8000);
	console.log('images/s (rAF, 12 Timeres) :', (await fps(bench, 6000)).toFixed(2));
	await waitLog(benchLogs, /draw calls/, 20000);
	await bench.screenshot({ path: `${SHOTS}/m1_web_bench.png` });
	dump('journal du banc', benchLogs);
	await browser.close();
})();
