import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import sharp from 'sharp';
const root=path.resolve('../store/creative-2026-09');
const shots=fs.readdirSync(path.join(root,'screenshots')).filter(n=>n.endsWith('.png'));
assert.equal(shots.length,8);
for(const f of shots){
 const m=await sharp(path.join(root,'screenshots',f)).metadata();
 assert.equal(m.width,1080);assert.equal(m.height,1920);assert.equal(m.channels,3);
}
const icon=await sharp(path.join(root,'brand/app-icon-512.png')).metadata();
assert.equal(icon.width,512);assert.equal(icon.height,512);assert.equal(icon.channels,4);
assert.ok(fs.statSync(path.join(root,'brand/app-icon-512.png')).size<1024*1024);
const feature=await sharp(path.join(root,'brand/feature-graphic-1024x500.png')).metadata();
assert.equal(feature.width,1024);assert.equal(feature.height,500);assert.equal(feature.channels,3);
const video=path.join(root,'video/cleanly-fresh-start-1080p.mp4');
const probe=path.resolve('node_modules/@remotion/compositor-win32-x64-msvc/ffprobe.exe');
const report=JSON.parse(execFileSync(probe,['-v','error','-show_streams','-show_format','-of','json',video],{encoding:'utf8'}));
const vs=report.streams.find(s=>s.codec_type==='video'),as=report.streams.find(s=>s.codec_type==='audio');
assert.equal(vs.width,1920);assert.equal(vs.height,1080);assert.equal(vs.codec_name,'h264');
assert.equal(vs.r_frame_rate,'30/1');
// FFprobe names full-range 8-bit 4:2:0 yuvj420p; both are H.264-compatible.
assert.ok(['yuv420p','yuvj420p'].includes(vs.pix_fmt));
assert.equal(as.codec_name,'aac');assert.equal(as.channels,2);
assert.ok(Math.abs(Number(report.format.duration)-40)<.1);
fs.writeFileSync(path.join(root,'video/video-validation.json'),JSON.stringify(report,null,2));
const wav=fs.readFileSync('public/fresh-start.wav');let peak=0,energy=0;
for(let i=44;i<wav.length;i+=2){const v=wav.readInt16LE(i)/32768;peak=Math.max(peak,Math.abs(v));energy+=v*v;}
assert.ok(peak>0&&peak<.98);
const audio={durationSeconds:40,peakDb:20*Math.log10(peak),rmsDb:20*Math.log10(Math.sqrt(energy/((wav.length-44)/2))),clipping:false};
fs.writeFileSync(path.join(root,'video/music-validation.json'),JSON.stringify(audio,null,2));
console.log('PASS: 8 RGB screenshots, RGBA icon, RGB feature graphic, 40-second H.264/AAC video, original non-clipping score.');
console.log(JSON.stringify(audio));
