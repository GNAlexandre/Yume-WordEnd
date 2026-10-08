#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const fsp = require('node:fs/promises');
const http = require('node:http');
const path = require('node:path');

function argument(name, fallback) {
  const position = process.argv.indexOf(name);
  return position === -1 ? fallback : process.argv[position + 1];
}

const root = path.resolve(argument('--root', path.resolve(__dirname, '../..')));
const output = path.resolve(argument('--output', '/workspace/sukasuka-production/atelier2d.png'));
const galleryPage = argument('--page', '/docs/sprites/ATELIER_2D.html');
const moduleName = process.env.PLAYWRIGHT_MODULE || '/workspace/sukasuka-production/viewer/node_modules/playwright-core';
const chromiumPath = process.env.CHROMIUM_PATH || '/usr/bin/chromium';
const { chromium } = require(moduleName);
const mime = { '.html': 'text/html; charset=utf-8', '.png': 'image/png', '.json': 'application/json' };

const server = http.createServer(async (request, response) => {
  try {
    const relative = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    const file = path.resolve(root, '.' + relative);
    if (file !== root && !file.startsWith(root + path.sep)) {
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
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  let browser;
  try {
    browser = await chromium.launch({ executablePath: chromiumPath, headless: true, args: ['--no-sandbox'] });
    const context = await browser.newContext({ viewport: { width: 1440, height: 1100 }, deviceScaleFactor: 1 });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('requestfailed', request => errors.push(request.url() + ': ' + request.failure().errorText));
    await page.goto(`http://127.0.0.1:${address.port}${galleryPage}`, { waitUntil: 'networkidle' });
    const images = await page.evaluate(async () => {
      const images = Array.from(document.images);
      await Promise.all(images.map(image => {
        image.loading = 'eager';
        if (image.complete) return Promise.resolve();
        return new Promise(resolve => {
          image.addEventListener('load', resolve, { once: true });
          image.addEventListener('error', resolve, { once: true });
        });
      }));
      return images.map(image => ({ src: image.src, loaded: image.complete && image.naturalWidth > 0, dimensions: [image.naturalWidth, image.naturalHeight] }));
    });
    const missing = images.filter(image => !image.loaded);
    if (missing.length) throw new Error('Images non chargées : ' + JSON.stringify(missing));
    const downloads = await page.locator('a[download]').evaluateAll(links => links.map(link => link.href));
    for (const url of downloads) {
      const response = await context.request.head(url);
      if (!response.ok()) throw new Error(`Téléchargement inaccessible : ${url} (${response.status()})`);
    }
    if (downloads.length !== images.length) throw new Error('Chaque image doit avoir un téléchargement.');
    const categories = await page.locator('[data-filter]').evaluateAll(buttons => buttons.map(button => button.dataset.filter));
    for (const category of categories) {
      await page.locator(`[data-filter="${category}"]`).click();
      const visible = await page.locator('section[data-category]').evaluateAll(sections => sections.filter(section => !section.hidden).map(section => section.dataset.category));
      if (category !== 'all' && (visible.length !== 1 || visible[0] !== category)) throw new Error('Filtre incorrect : ' + category);
    }
    await page.locator('[data-filter="all"]').click();
    await page.screenshot({ path: output });
    await page.setViewportSize({ width: 390, height: 844 });
    const mobileWidth = await page.evaluate(() => ({ document: document.documentElement.scrollWidth, viewport: innerWidth }));
    if (mobileWidth.document > mobileWidth.viewport) throw new Error('Débordement horizontal mobile : ' + JSON.stringify(mobileWidth));
    const mobileOutput = output.replace(/\.png$/i, '') + '-mobile.png';
    await page.screenshot({ path: mobileOutput });
    if (errors.length) throw new Error('Erreurs navigateur : ' + JSON.stringify(errors));
    const report = { gallery: galleryPage, images: images.length, downloads: downloads.length, all_images_loaded: true, all_downloads_available: true, filters_checked: categories, browser_errors: errors, mobile_width: mobileWidth, screenshots: [output, mobileOutput] };
    await fsp.writeFile(output.replace(/\.png$/i, '') + '-validation.json', JSON.stringify(report, null, 2) + '\n');
    process.stdout.write(JSON.stringify(report) + '\n');
  } finally {
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
}

main().catch(error => {
  process.stderr.write(error.stack + '\n');
  process.exitCode = 1;
});
