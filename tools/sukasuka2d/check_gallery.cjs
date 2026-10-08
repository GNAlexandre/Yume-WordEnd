#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const fsp = require('node:fs/promises');
const http = require('node:http');
const crypto = require('node:crypto');
const os = require('node:os');
const path = require('node:path');

function argument(name, fallback) {
  const position = process.argv.indexOf(name);
  return position === -1 ? fallback : process.argv[position + 1];
}

const root = path.resolve(argument('--root', path.resolve(__dirname, '../..')));
const output = path.resolve(argument('--output', '/workspace/sukasuka-production/atelier2d.png'));
const galleryPage = argument('--page', '/docs/sprites/ATELIER_2D.html');
const galleryFile = argument('--file', null);
const isolated = process.argv.includes('--isolated');
const verifyDownloads = isolated || process.argv.includes('--verify-downloads');
const verbose = process.argv.includes('--verbose');
const progress = message => {
  if (verbose) process.stderr.write(`[galerie ${new Date().toISOString()}] ${message}\n`);
};
let servingRoot = root;
const moduleName = process.env.PLAYWRIGHT_MODULE || '/workspace/sukasuka-production/viewer/node_modules/playwright-core';
const chromiumPath = process.env.CHROMIUM_PATH || '/usr/bin/chromium';
const { chromium } = require(moduleName);
const mime = { '.html': 'text/html; charset=utf-8', '.png': 'image/png', '.json': 'application/json' };

const server = http.createServer(async (request, response) => {
  try {
    const relative = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    const file = path.resolve(servingRoot, '.' + relative);
    if (file !== servingRoot && !file.startsWith(servingRoot + path.sep)) {
      response.writeHead(403).end();
      return;
    }
    const stat = await fsp.stat(file);
    if (!stat.isFile()) {
      response.writeHead(404).end();
      return;
    }
    response.writeHead(200, { 'Content-Type': mime[path.extname(file)] || 'application/octet-stream', 'Content-Length': stat.size });
    if (request.method === 'HEAD') response.end();
    else fs.createReadStream(file).pipe(response);
  } catch {
    response.writeHead(404).end();
  }
});

async function main() {
  await fsp.mkdir(path.dirname(output), { recursive: true });
  let temporary;
  let requestedPage = galleryPage;
  let browser;
  try {
    if (isolated) {
      temporary = await fsp.mkdtemp(path.join(os.tmpdir(), 'atelier2d-isolated-'));
      const original = galleryFile ? path.resolve(root, galleryFile) : path.resolve(root, '.' + galleryPage);
      await fsp.copyFile(original, path.join(temporary, 'gallery.html'));
      servingRoot = temporary;
      requestedPage = '/gallery.html';
    } else if (galleryFile) {
      requestedPage = '/' + path.relative(root, path.resolve(root, galleryFile)).split(path.sep).join('/');
    }
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const address = server.address();
    const pageURL = `http://127.0.0.1:${address.port}${requestedPage}`;
    progress('Démarrage Chromium ; HTML seul : ' + isolated);
    browser = await chromium.launch({ executablePath: chromiumPath, headless: true, args: ['--no-sandbox'] });
    const context = await browser.newContext({ viewport: { width: 1440, height: 1100 }, deviceScaleFactor: 1 });
    const page = await context.newPage();
    await page.exposeFunction('reportGalleryProgress', progress);
    const errors = [];
    const externalRequests = [];
    page.setDefaultTimeout(120000);
    page.on('pageerror', error => errors.push(error.message));
    page.on('requestfailed', request => errors.push(request.url() + ': ' + request.failure().errorText));
    page.on('request', request => {
      if (isolated && /^https?:/.test(request.url()) && request.url() !== pageURL) externalRequests.push(request.url());
    });
    progress('Chargement du document');
    await page.goto(pageURL, { waitUntil: 'networkidle', timeout: 120000 });
    progress('Document chargé ; décodage des PNG');
    const images = await page.evaluate(async () => {
      const images = Array.from(document.images);
      images.forEach(image => { image.loading = 'eager'; });
      const results = [];
      for (const [index, image] of images.entries()) {
        const diagnostic = () => JSON.stringify({
          index, alt: image.alt, complete: image.complete,
          dimensions: [image.naturalWidth, image.naturalHeight],
          src_prefix: image.src.slice(0, 30),
        });
        let timer;
        try {
          // decode() observes the current image request even if its load event
          // fired before a listener was installed. Never await lazy load events
          // indefinitely inside a Playwright evaluate() call.
          await Promise.race([
            image.decode().catch(error => { throw new Error('PNG indécodable : ' + diagnostic() + ' ; ' + error.message); }),
            new Promise((resolve, reject) => {
              timer = setTimeout(() => reject(new Error('Décodage PNG bloqué : ' + diagnostic())), 15000);
            }),
          ]);
        } finally {
          clearTimeout(timer);
        }
        let dataHash = null;
        if (image.src.startsWith('data:')) {
          const encoded = await fetch(image.src);
          const digest = await crypto.subtle.digest('SHA-256', await encoded.arrayBuffer());
          dataHash = Array.from(new Uint8Array(digest)).map(byte => byte.toString(16).padStart(2, '0')).join('');
        }
        results.push({
          src: image.src.startsWith('data:') ? 'data:image/png;base64,…' : image.src,
          loaded: image.complete && image.naturalWidth > 0,
          dimensions: [image.naturalWidth, image.naturalHeight],
          data_hash: dataHash,
          expected_hash: image.dataset.sha256 || null,
        });
        if ((index + 1) % 10 === 0 || index + 1 === images.length) {
          await window.reportGalleryProgress(`PNG décodés et hachés : ${index + 1}/${images.length}`);
        }
      }
      return results;
    });
    const missing = images.filter(image => !image.loaded);
    if (missing.length) throw new Error('Images non chargées : ' + JSON.stringify(missing));
    const invalidHashes = images.filter(image => image.data_hash && image.data_hash !== image.expected_hash);
    if (invalidHashes.length) throw new Error('Octets PNG incorporés modifiés : ' + JSON.stringify(invalidHashes));
    const downloadLinks = page.locator('article a[download]');
    const downloadCount = await downloadLinks.count();
    progress(`Vérification de ${downloadCount} téléchargements PNG`);
    if (downloadCount !== images.length) throw new Error('Chaque image doit avoir un téléchargement.');
    let hashesChecked = 0;
    for (let index = 0; index < downloadCount; index++) {
      const link = downloadLinks.nth(index);
      const href = await link.getAttribute('href');
      if (verifyDownloads || images[index].data_hash || /^(blob:|data:)/.test(href)) {
        // Chromium limits bursts of automatic downloads. Keep the real clicks
        // below ten per second instead of letting its limiter block the 11th.
        await new Promise(resolve => setTimeout(resolve, 200));
        const [download] = await Promise.all([
          page.waitForEvent('download', { timeout: 10000 }),
          link.click({ timeout: 10000 }),
        ]);
        const failure = await download.failure();
        if (failure) throw new Error('Téléchargement refusé : ' + failure);
        const file = await download.path();
        const digest = crypto.createHash('sha256').update(await fsp.readFile(file)).digest('hex');
        if (images[index].data_hash && digest !== images[index].data_hash) throw new Error('SHA-256 du téléchargement incorrect : ' + download.suggestedFilename());
        if (images[index].data_hash) hashesChecked++;
        await download.delete();
      } else {
        const url = await link.evaluate(element => element.href);
        const response = await context.request.head(url);
        if (!response.ok()) throw new Error(`Téléchargement inaccessible : ${url} (${response.status()})`);
      }
      if ((index + 1) % 10 === 0 || index + 1 === downloadCount) progress(`Téléchargements PNG vérifiés : ${index + 1}/${downloadCount}`);
    }
    const jsonLinks = page.locator('[data-embedded-json]');
    const jsonCount = await jsonLinks.count();
    progress(`Vérification de ${jsonCount} manifeste(s) JSON`);
    for (let index = 0; index < jsonCount; index++) {
      const link = jsonLinks.nth(index);
      const source = await link.evaluate(element => document.getElementById(element.dataset.embeddedJson).textContent);
      await new Promise(resolve => setTimeout(resolve, 200));
      const [download] = await Promise.all([
        page.waitForEvent('download', { timeout: 10000 }),
        link.click({ timeout: 10000 }),
      ]);
      const text = await fsp.readFile(await download.path(), 'utf8');
      JSON.parse(text);
      if (text !== source) throw new Error('Manifeste JSON téléchargé modifié.');
      await download.delete();
    }
    const categories = await page.locator('[data-filter]').evaluateAll(buttons => buttons.map(button => button.dataset.filter));
    progress('Filtres, captures et affichage mobile');
    for (const category of categories) {
      await page.locator(`[data-filter="${category}"]`).click();
      const visible = await page.locator('section[data-category]').evaluateAll(sections => sections.filter(section => !section.hidden).map(section => section.dataset.category));
      if (category !== 'all' && (visible.length !== 1 || visible[0] !== category)) throw new Error('Filtre incorrect : ' + category);
    }
    await page.locator('[data-filter="all"]').click();
    await page.evaluate(() => scrollTo(0, 0));
    await page.screenshot({ path: output });
    await page.setViewportSize({ width: 390, height: 844 });
    const mobileWidth = await page.evaluate(() => ({ document: document.documentElement.scrollWidth, viewport: innerWidth }));
    if (mobileWidth.document > mobileWidth.viewport) throw new Error('Débordement horizontal mobile : ' + JSON.stringify(mobileWidth));
    const mobileOutput = output.replace(/\.png$/i, '') + '-mobile.png';
    await page.screenshot({ path: mobileOutput });
    if (errors.length) throw new Error('Erreurs navigateur : ' + JSON.stringify(errors));
    if (externalRequests.length) throw new Error('La page autonome demande des fichiers extérieurs : ' + JSON.stringify(externalRequests));
    const report = { gallery: galleryFile || galleryPage, isolated_html_only: isolated, images: images.length, downloads: downloadCount, download_sha256_checked: hashesChecked, manifest_downloads_checked: jsonCount, all_images_loaded: true, all_downloads_available: true, external_requests: externalRequests, filters_checked: categories, browser_errors: errors, mobile_width: mobileWidth, screenshots: [output, mobileOutput] };
    await fsp.writeFile(output.replace(/\.png$/i, '') + '-validation.json', JSON.stringify(report, null, 2) + '\n');
    process.stdout.write(JSON.stringify(report) + '\n');
  } finally {
    progress('Fermeture Chromium et serveur temporaire');
    if (browser) await browser.close();
    if (server.listening) await new Promise(resolve => server.close(resolve));
    if (temporary) await fsp.rm(temporary, { recursive: true, force: true });
  }
}

main().catch(error => {
  process.stderr.write(error.stack + '\n');
  process.exitCode = 1;
});
