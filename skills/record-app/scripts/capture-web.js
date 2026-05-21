#!/usr/bin/env node
// capture-web.js — Playwright built-in video recording for web app capture
// Usage: node capture-web.js <config.json>
// Config format: see SKILL.md Phase 2 example

import { chromium } from 'playwright';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// H.264 requires even dimensions
function even(n) {
  return n % 2 === 0 ? n : n + 1;
}

function getViewportConfig(viewport) {
  if (viewport === 'mobile') {
    return {
      width: 375,
      height: 812,
      videoWidth: even(375), // 376
      videoHeight: even(812), // 812
    };
  }
  return {
    width: 1280,
    height: 720,
    videoWidth: 1280,
    videoHeight: 720,
  };
}

function getMusicFile(genre) {
  const files = {
    beethoven: 'beethoven-sonata-32.mp3',
  };
  const filename = files[genre] || files.beethoven;
  const localDir = path.join(__dirname, '..', 'music');
  const globalDir = path.join(process.env.HOME || '', '.config', 'opencode', 'skills', 'record-app', 'music');

  const localPath = path.join(localDir, filename);
  if (fs.existsSync(localPath)) return localPath;

  const globalPath = path.join(globalDir, filename);
  if (fs.existsSync(globalPath)) return globalPath;

  return null;
}

function findMusicFile(music) {
  if (!music || music === 'none') return null;
  // If user provided a direct path, use it
  if (fs.existsSync(music)) return music;
  // Look up by genre
  const result = getMusicFile(music);
  if (!result) {
    console.warn(`Music file for '${music}' not found; skipping audio.`);
  }
  return result;
}

async function main() {
  const configFile = process.argv[2];
  if (!configFile) {
    console.error('Usage: node capture-web.js <config.json>');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));
  const { url, scenes, output, viewport = 'desktop', music = 'none' } = config;

  const vp = getViewportConfig(viewport);
  const outputDir = path.dirname(output);
  const clipsDir = path.join(outputDir, '.clips');
  fs.mkdirSync(outputDir, { recursive: true });
  fs.mkdirSync(clipsDir, { recursive: true });

  const mp4Output = output.endsWith('.mp4') ? output : output.replace(/\.\w+$/, '.mp4');
  const durationPerScene = 4;

  console.log(`Starting video capture for ${url} (${viewport})...`);
  console.log(`Viewport: ${vp.width}x${vp.height}, Video: ${vp.videoWidth}x${vp.videoHeight}`);
  console.log(`Scenes: ${scenes.map(s => s.name).join(', ')}`);

  const browser = await chromium.launch();
  const recordedClips = [];

  for (const scene of scenes) {
    const clipPath = path.join(clipsDir, `${scene.name}-${viewport}.webm`);
    const screenshotPath = path.join(outputDir, `${scene.name}-${viewport}-web.png`);

    console.log(`\nRecording: ${scene.name} (${scene.path})`);

    // Each scene gets its own context so video is available on close
    const context = await browser.newContext({
      viewport: { width: vp.width, height: vp.height },
      recordVideo: {
        dir: clipsDir,
        size: { width: vp.videoWidth, height: vp.videoHeight },
      },
    });

    const page = await context.newPage();

    try {
      await page.goto(`${url}${scene.path}`, { waitUntil: 'networkidle', timeout: 15000 });
      await page.waitForTimeout(1000);

      // Perform scene interactions if specified
      if (scene.interactions) {
        for (const action of scene.interactions) {
          await performInteraction(page, action);
        }
      }

      // Hold for duration to capture meaningful video
      await page.waitForTimeout(durationPerScene * 1000);

      // Screenshot for gallery (still useful for README embedding)
      await page.screenshot({ path: screenshotPath, fullPage: false, type: 'png' });
      console.log(`  Screenshot: ${screenshotPath}`);

    } catch (err) {
      console.warn(`  Error on ${scene.name}: ${err.message}`);
    }

    // Close context to finalize the video
    await context.close();

    // Playwright saves video with a random name; find and rename it
    const videoFile = findLatestVideo(clipsDir, clipPath);
    if (videoFile) {
      recordedClips.push(videoFile);
      console.log(`  Video: ${videoFile}`);
    } else {
      console.warn(`  No video captured for ${scene.name}`);
    }
  }

  await browser.close();

  if (recordedClips.length === 0) {
    console.error('No video clips captured.');
    process.exit(1);
  }

  // Stitch recorded clips into final MP4
  console.log('\nStitching final video...');
  const musicFile = findMusicFile(music);
  const ffmpegCmd = buildStitchCommand(recordedClips, mp4Output, vp, musicFile, durationPerScene);
  console.log(`Running ffmpeg...`);
  try {
    execSync(ffmpegCmd, { stdio: 'inherit' });
  } catch (err) {
    console.error('ffmpeg failed. Install: brew install ffmpeg');
    process.exit(1);
  }

  // Create gallery versions at 1200px width
  console.log('\nCreating gallery versions...');
  const screenshotPattern = `-${viewport}-web.png`;
  let screenshots = [];
  try {
    screenshots = fs.readdirSync(outputDir)
      .filter(f => f.endsWith(screenshotPattern) && !f.includes('-gallery'))
      .map(f => path.join(outputDir, f));
  } catch {
    // outputDir may not exist
  }
  for (const screenshotPath of screenshots) {
      const galleryPath = screenshotPath.replace('.png', '-gallery.png');
      try {
        execSync(`sips -Z 1200 "${screenshotPath}" --out "${galleryPath}" 2>/dev/null`, { stdio: 'pipe' });
        console.log(`  Gallery: ${galleryPath}`);
      } catch {
        try {
          execSync(`ffmpeg -y -i "${screenshotPath}" -vf "scale=1200:-2" -q:v 2 "${galleryPath}" 2>/dev/null`, { stdio: 'pipe' });
          console.log(`  Gallery: ${galleryPath}`);
        } catch {
          fs.copyFileSync(screenshotPath, galleryPath);
        }
      }
    }
  } catch {
    console.log('  No screenshots to resize.');
  }

  // Clean up clips directory and old .webm files
  console.log('\nCleaning up...');
  if (fs.existsSync(clipsDir)) {
    for (const file of fs.readdirSync(clipsDir)) {
      const filePath = path.join(clipsDir, file);
      fs.unlinkSync(filePath);
    }
    fs.rmdirSync(clipsDir);
  }
  // Also clean any stray .webm in output dir
  for (const file of fs.readdirSync(outputDir)) {
    if (file.endsWith('.webm')) {
      fs.unlinkSync(path.join(outputDir, file));
      console.log(`  Removed: ${file}`);
    }
  }

  console.log(`\nDone: ${mp4Output}`);
}

function findLatestVideo(dir, expectedPath) {
  // Playwright names videos like <uuid>.webm — find the most recent one
  const files = fs.readdirSync(dir)
    .filter(f => f.endsWith('.webm'))
    .map(f => ({
      name: f,
      path: path.join(dir, f),
      mtime: fs.statSync(path.join(dir, f)).mtimeMs,
    }))
    .sort((a, b) => b.mtime - a.mtime);

  if (files.length === 0) return null;

  const latest = files[0];
  // Rename to expected path for clarity
  fs.renameSync(latest.path, expectedPath);
  return expectedPath;
}

async function performInteraction(page, action) {
  switch (action.type) {
    case 'click':
      await page.click(action.selector);
      await page.waitForTimeout(500);
      break;
    case 'fill':
      await page.fill(action.selector, action.value);
      await page.waitForTimeout(300);
      break;
    case 'navigate':
      await page.goto(action.url, { waitUntil: 'networkidle', timeout: 10000 });
      await page.waitForTimeout(500);
      break;
    case 'scroll':
      await page.evaluate((delta) => window.scrollBy(0, delta), action.delta || 300);
      await page.waitForTimeout(500);
      break;
    case 'wait':
      await page.waitForTimeout(action.duration || 1000);
      break;
    case 'hover':
      await page.hover(action.selector);
      await page.waitForTimeout(500);
      break;
  }
}

function buildStitchCommand(clipPaths, output, vp, musicFile, durationPerScene) {
  const w = even(vp.videoWidth);
  const h = even(vp.videoHeight);

  if (clipPaths.length === 1) {
    // Single clip: just re-encode to H.264
    let audioPart = '';
    if (musicFile) {
      audioPart = `-stream_loop -1 -i "${musicFile}" -filter_complex "[1:a]volume=0.15,afade=t=in:st=0:d=2,afade=t=out:st=${durationPerScene - 2}:d=2[aout]" -map "[aout]" -c:a aac -b:a 192k`;
      return `ffmpeg -y -i "${clipPaths[0]}" ${audioPart} -map 0:v -c:v libx264 -crf 18 -tune animation -pix_fmt yuv420p -movflags +faststart "${output}"`;
    }
    return `ffmpeg -y -i "${clipPaths[0]}" -c:v libx264 -crf 18 -tune animation -pix_fmt yuv420p -movflags +faststart "${output}"`;
  }

  // Multiple clips: concat then re-encode
  // Create a concat file list
  const concatFile = path.join(path.dirname(output), '.concat-list.txt');
  const concatContent = clipPaths.map(p => `file '${p.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`).join('\n');
  fs.writeFileSync(concatFile, concatContent);

  let audioPart = '';
  const totalDuration = clipPaths.length * durationPerScene;

  if (musicFile) {
    audioPart = `-stream_loop -1 -i "${musicFile}" -filter_complex "[1:a]volume=0.15,afade=t=in:st=0:d=2,afade=t=out:st=${totalDuration - 2}:d=2[aout]" -map "[aout]" -c:a aac -b:a 192k`;
  }

  return `ffmpeg -y -f concat -safe 0 -i "${concatFile}" ${audioPart} -map 0:v -c:v libx264 -crf 18 -tune animation -pix_fmt yuv420p -movflags +faststart "${output}"`;
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
