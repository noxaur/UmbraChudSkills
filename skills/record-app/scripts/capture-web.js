#!/usr/bin/env node
// capture-web.js — Playwright-based web app capture
// Usage: node capture-web.js <config.json>
// Config format: see SKILL.md Phase 2 example

import { chromium } from 'playwright';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const scriptsDir = __dirname;

async function main() {
  const configFile = process.argv[2];
  if (!configFile) {
    console.error('Usage: node capture-web.js <config.json>');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));
  const { url, scenes, output, viewport = 'desktop' } = config;

  const viewportSize = viewport === 'mobile'
    ? { width: 375, height: 812 }
    : { width: 1280, height: 720 };

  const outputDir = path.dirname(output);
  fs.mkdirSync(outputDir, { recursive: true });

  // Gallery dir for individual resized screenshots
  const galleryDir = outputDir;

  console.log(`Starting capture for ${url} (${viewport})...`);
  console.log(`Scenes: ${scenes.map(s => s.name).join(', ')}`);

  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: viewportSize });
  const page = await context.newPage();

  const screenshotPaths = [];

  for (const scene of scenes) {
    console.log(`\nCapturing: ${scene.name} (${scene.path})`);

    try {
      await page.goto(`${url}${scene.path}`, { waitUntil: 'networkidle', timeout: 15000 });
      await page.waitForTimeout(1000); // Let animations settle

      // Save full-res screenshot for video stitching
      const screenshotPath = path.join(outputDir, `${scene.name}-${viewport}-web.png`);
      await page.screenshot({ path: screenshotPath, fullPage: false });
      screenshotPaths.push(screenshotPath);

      console.log(`  Captured: ${screenshotPath}`);
    } catch (err) {
      console.warn(`  Skipping ${scene.name}: ${err.message}`);
    }
  }

  await browser.close();

  // Resize screenshots for gallery (max 400px width)
  console.log('\nResizing for gallery...');
  for (const screenshotPath of screenshotPaths) {
    const resizedPath = screenshotPath.replace('.png', '-gallery.png');
    try {
      execSync(`sips -Z 400 "${screenshotPath}" --out "${resizedPath}" 2>/dev/null`, { stdio: 'pipe' });
      console.log(`  Resized: ${resizedPath}`);
    } catch {
      // sips not available, try ffmpeg
      try {
        execSync(`ffmpeg -y -i "${screenshotPath}" -vf "scale=400:-1" "${resizedPath}" 2>/dev/null`, { stdio: 'pipe' });
        console.log(`  Resized: ${resizedPath}`);
      } catch {
        console.warn(`  Resize failed for ${screenshotPath}, using original`);
        // Copy original as gallery version
        fs.copyFileSync(screenshotPath, resizedPath);
      }
    }
  }

  // Stitch into final demo video
  console.log('\nStitching final video...');
  const ffmpegCmd = buildFfmpegCommand(screenshotPaths, output, scenes, viewport);
  console.log(`Running: ${ffmpegCmd}`);
  try {
    execSync(ffmpegCmd, { stdio: 'inherit' });
  } catch (err) {
    console.error('ffmpeg failed. Installing ffmpeg may be required.');
    console.error('  macOS: brew install ffmpeg');
    console.error('  Linux: sudo apt install ffmpeg');
    console.error('  Windows: choco install ffmpeg');
    process.exit(1);
  }

  // Delete full-res screenshots (keep resized gallery versions + video)
  for (const screenshotPath of screenshotPaths) {
    fs.unlinkSync(screenshotPath);
  }

  console.log(`\nDone: ${output}`);
  console.log(`Gallery images: ${screenshotPaths.map(p => p.replace('.png', '-gallery.png')).join(', ')}`);
}

function buildFfmpegCommand(clipPaths, output, scenes, viewport) {
  if (clipPaths.length === 0) {
    return '';
  }

  const isMobile = viewport === 'mobile';
  const targetRes = isMobile ? '375:812' : '1280:720';

  if (clipPaths.length === 1) {
    // Single image → 5s video with zoom-in effect
    const scene = scenes[0];
    const effects = scene.effects || [];
    let filter = `zoompan=z='min(zoom+0.0015,1.5)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${targetRes}:fps=25`;
    if (effects.includes('pan-down')) {
      filter = `zoompan=z='min(zoom+0.001,1.3)':d=125:x='iw/2-(iw/zoom/2)':y='ih*0.3-(ih/zoom/2)':s=${targetRes}:fps=25`;
    }
    return `ffmpeg -y -loop 1 -i "${clipPaths[0]}" -vf "${filter}" -t 5 -c:v libvpx-vp9 -pix_fmt yuv420p "${output}"`;
  }

  // Multiple images → Ken Burns sequence with fade transitions
  const inputs = clipPaths.map(p => `-loop 1 -t 3 -i "${p}"`).join(' ');

  let filterComplex = '';
  for (let i = 0; i < clipPaths.length; i++) {
    filterComplex += `[${i}:v]scale=${targetRes},setsar=1,fps=25[v${i}];`;
  }

  // Chain with fade transitions
  filterComplex += '[v0][v1]xfade=transition=fade:duration=0.5:offset=2.5[t1];';
  for (let i = 2; i < clipPaths.length; i++) {
    const offset = ((i - 1) * 2500) / 1000;
    filterComplex += `[t${i-1}][v${i}]xfade=transition=fade:duration=0.5:offset=${offset}[t${i}];`;
  }
  filterComplex += `[t${clipPaths.length - 1}]null[outv]`;

  return `ffmpeg -y ${inputs} -filter_complex "${filterComplex}" -map "[outv]" -c:v libvpx-vp9 -pix_fmt yuv420p "${output}"`;
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
