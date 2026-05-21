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

async function main() {
  const configFile = process.argv[2];
  if (!configFile) {
    console.error('Usage: node capture-web.js <config.json>');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));
  const { url, scenes, output, viewport = 'desktop', music = 'jazz' } = config;

  const viewportSize = viewport === 'mobile'
    ? { width: 375, height: 812 }
    : { width: 1280, height: 720 };

  const outputDir = path.dirname(output);
  fs.mkdirSync(outputDir, { recursive: true });

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
      await page.waitForTimeout(1000);

      const screenshotPath = path.join(outputDir, `${scene.name}-${viewport}-web.png`);
      await page.screenshot({ path: screenshotPath, fullPage: false, type: 'png' });
      screenshotPaths.push(screenshotPath);

      console.log(`  Captured: ${screenshotPath}`);
    } catch (err) {
      console.warn(`  Skipping ${scene.name}: ${err.message}`);
    }
  }

  await browser.close();

  if (screenshotPaths.length === 0) {
    console.error('No screenshots captured.');
    process.exit(1);
  }

  // Create gallery versions at 1200px (keep originals at full res)
  console.log('\nCreating gallery versions...');
  const galleryPaths = [];
  for (const screenshotPath of screenshotPaths) {
    const galleryPath = screenshotPath.replace('.png', '-gallery.png');
    galleryPaths.push(galleryPath);
    try {
      execSync(`sips -Z 1200 "${screenshotPath}" --out "${galleryPath}" 2>/dev/null`, { stdio: 'pipe' });
      console.log(`  Gallery: ${galleryPath}`);
    } catch {
      try {
        execSync(`ffmpeg -y -i "${screenshotPath}" -vf "scale=1200:-2" -q:v 2 "${galleryPath}" 2>/dev/null`, { stdio: 'pipe' });
        console.log(`  Gallery: ${galleryPath}`);
      } catch {
        fs.copyFileSync(screenshotPath, galleryPath);
        console.log(`  Copied original: ${galleryPath}`);
      }
    }
  }

  // Stitch into final demo video (MP4, H.264, preserve aspect ratio)
  console.log('\nStitching final video...');
  const mp4Output = output.endsWith('.mp4') ? output : output.replace(/\.\w+$/, '.mp4');
  const ffmpegCmd = buildFfmpegCommand(screenshotPaths, mp4Output, scenes, viewport, music);
  console.log(`Running: ${ffmpegCmd}`);
  try {
    execSync(ffmpegCmd, { stdio: 'inherit' });
  } catch (err) {
    console.error('ffmpeg failed. Install: brew install ffmpeg');
    process.exit(1);
  }

  console.log(`\nDone: ${mp4Output}`);
  console.log(`Gallery images: ${galleryPaths.join(', ')}`);

  // Clean up old webm files from previous runs
  for (const file of fs.readdirSync(outputDir)) {
    if (file.endsWith('.webm')) {
      const webmPath = path.join(outputDir, file);
      fs.unlinkSync(webmPath);
      console.log(`  Cleaned up: ${file}`);
    }
  }
}

function buildFfmpegCommand(clipPaths, output, scenes, viewport, music) {
  if (clipPaths.length === 0) return '';

  const firstPath = clipPaths[0];
  let origWidth, origHeight;
  try {
    const info = execSync(`ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "${firstPath}" 2>/dev/null || echo "1280x720"`).toString().trim();
    [origWidth, origHeight] = info.split('x').map(Number);
  } catch {
    origWidth = viewport === 'mobile' ? 375 : 1280;
    origHeight = viewport === 'mobile' ? 812 : 720;
  }

  // H.264 requires even dimensions — force even
  if (origWidth % 2 !== 0) origWidth += 1;
  if (origHeight % 2 !== 0) origHeight += 1;

  const durationPerScene = 4;
  const fps = 30;

  if (clipPaths.length === 1) {
    const scene = scenes[0];
    const effects = scene.effects || [];
    let filter = `zoompan=z='min(zoom+0.0015,1.5)':d=${durationPerScene * fps}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${origWidth}x${origHeight}:fps=${fps}`;
    if (effects.includes('pan-down')) {
      filter = `zoompan=z='min(zoom+0.001,1.3)':d=${durationPerScene * fps}:x='iw/2-(iw/zoom/2)':y='ih*0.3-(ih/zoom/2)':s=${origWidth}x${origHeight}:fps=${fps}`;
    }
    if (effects.includes('pan-across')) {
      filter = `zoompan=z='min(zoom+0.001,1.3)':d=${durationPerScene * fps}:x='iw*0.2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${origWidth}x${origHeight}:fps=${fps}`;
    }

    let audioPart = '';
    if (music && music !== 'none') {
      const musicFile = getMusicFile(music);
      if (fs.existsSync(musicFile)) {
        audioPart = `-stream_loop -1 -i "${musicFile}" -filter_complex "[1:a]volume=0.15,afade=t=in:st=0:d=2,afade=t=out:st=${durationPerScene - 2}:d=2[aout]" -map "[aout]" -c:a aac -b:a 192k`;
      } else {
        console.log(`  Music file not found: ${musicFile}, skipping audio`);
      }
    }

    return `ffmpeg -y -loop 1 -i "${clipPaths[0]}" ${audioPart} -vf "${filter}" -t ${durationPerScene} -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart "${output}"`;
  }

  // Multiple images → Ken Burns with fade transitions, preserve aspect ratio
  const inputs = clipPaths.map(p => `-loop 1 -t ${durationPerScene} -i "${p}"`).join(' ');

  let filterComplex = '';
  for (let i = 0; i < clipPaths.length; i++) {
    filterComplex += `[${i}:v]scale=${origWidth}:${origHeight},setsar=1,fps=${fps}[v${i}];`;
  }

  const transitionDuration = 0.5;
  filterComplex += `[v0][v1]xfade=transition=fade:duration=${transitionDuration}:offset=${durationPerScene - transitionDuration}[t1];`;
  for (let i = 2; i < clipPaths.length; i++) {
    const offset = ((i - 1) * (durationPerScene * 1000 - transitionDuration * 1000)) / 1000;
    filterComplex += `[t${i-1}][v${i}]xfade=transition=fade:duration=${transitionDuration}:offset=${offset}[t${i}];`;
  }
  const lastIdx = clipPaths.length - 1;

  let audioPart = '';
  const totalDuration = clipPaths.length * durationPerScene - (clipPaths.length - 1) * transitionDuration;
  if (music && music !== 'none') {
    const musicFile = getMusicFile(music);
    if (fs.existsSync(musicFile)) {
      filterComplex += `[t${lastIdx}]format=yuv420p[outv]`;
      audioPart = `-stream_loop -1 -i "${musicFile}" -filter_complex "${filterComplex};[1:a]volume=0.15,afade=t=in:st=0:d=2,afade=t=out:st=${totalDuration - 2}:d=2[aout]" -map "[outv]" -map "[aout]" -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart -c:a aac -b:a 192k`;
    } else {
      console.log(`  Music file not found: ${musicFile}, skipping audio`);
      filterComplex += `[t${lastIdx}]format=yuv420p[outv]`;
      audioPart = `-filter_complex "${filterComplex}" -map "[outv]" -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart`;
    }
  } else {
    filterComplex += `[t${lastIdx}]format=yuv420p[outv]`;
    audioPart = `-filter_complex "${filterComplex}" -map "[outv]" -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart`;
  }

  return `ffmpeg -y ${inputs} ${audioPart} "${output}"`;
}

function getMusicFile(genre) {
  const musicDir = path.join(__dirname, '..', 'music');
  const globalMusicDir = path.join(process.env.HOME || '', '.config', 'opencode', 'skills', 'record-app', 'music');
  const files = {
    beethoven: 'beethoven-sonata-32.mp3',
    jazz: 'smooth-jazz.mp3',
    lofi: 'lofi-beat.mp3',
    ambient: 'ambient.mp3',
  };
  const filename = files[genre] || files.beethoven;
  // Try local music dir first, then global
  const localPath = path.join(musicDir, filename);
  if (fs.existsSync(localPath)) return localPath;
  const globalPath = path.join(globalMusicDir, filename);
  if (fs.existsSync(globalPath)) return globalPath;
  return localPath; // return local path even if missing (caller checks exists)
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
