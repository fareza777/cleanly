// Original procedural instrumental: 96 BPM, soft electric-piano arpeggios,
// warm sustained chords and restrained pulse. No samples or licensed music.
import fs from "node:fs";
const sr = 48000,
  seconds = 40,
  n = sr * seconds;
const left = new Float32Array(n),
  right = new Float32Array(n);
const beat = 60 / 96;
const chords = [
  [48, 55, 59, 64, 67],
  [45, 52, 55, 60, 64],
  [41, 48, 52, 57, 60],
  [43, 50, 55, 57, 62],
];
function tone(midi, start, duration, gain, pan = 0, pad = false) {
  const hz = 440 * 2 ** ((midi - 69) / 12);
  const from = Math.round(start * sr),
    len = Math.round(duration * sr);
  for (let j = 0; j < len && from + j < n; j++) {
    const t = j / sr;
    const env = pad
      ? Math.min(1, t / 0.5) * Math.min(1, (duration - t) / 0.8)
      : Math.min(1, t / 0.008) *
        Math.exp(-t / 1.1) *
        Math.min(1, (duration - t) / 0.08);
    const signal =
      (Math.sin(2 * Math.PI * hz * t) +
        0.23 * Math.sin(2 * Math.PI * hz * 2 * t) +
        0.08 * Math.sin(2 * Math.PI * hz * 3 * t)) *
      0.65 *
      gain *
      env;
    left[from + j] += signal * (1 - pan * 0.5);
    right[from + j] += signal * (1 + pan * 0.5);
  }
}
for (let bar = 0; bar < 16; bar++) {
  const chord = chords[bar % 4],
    t = bar * beat * 4;
  for (const note of chord) tone(note, t, beat * 4 + 0.65, 0.033, 0, true);
  tone(chord[0] - 12, t, 1.6, 0.13, 0);
  for (let i = 0; i < 8; i++)
    tone(
      chord[[0, 2, 3, 1, 4, 2, 3, 1][i]] + 12,
      t + (i * beat) / 2,
      1.8,
      0.1,
      i % 2 ? 0.5 : -0.5,
    );
  if (bar > 3)
    for (let i = 0; i < 4; i++) tone(84, t + i * beat, 0.055, 0.025, 0);
}
// Stereo feedback-free room taps.
for (let i = n - 1; i >= 0; i--) {
  const d = Math.round(0.19 * sr),
    d2 = Math.round(0.37 * sr);
  if (i >= d) {
    left[i] += right[i - d] * 0.18;
    right[i] += left[i - d] * 0.16;
  }
  if (i >= d2) {
    left[i] += left[i - d2] * 0.09;
    right[i] += right[i - d2] * 0.09;
  }
}
const pcm = Buffer.alloc(n * 4);
for (let i = 0; i < n; i++) {
  const fade = Math.min(1, i / (sr * 0.6), (n - i) / (sr * 2));
  pcm.writeInt16LE(
    Math.round(Math.tanh(left[i] * 1.8) * 0.75 * fade * 32767),
    i * 4,
  );
  pcm.writeInt16LE(
    Math.round(Math.tanh(right[i] * 1.8) * 0.75 * fade * 32767),
    i * 4 + 2,
  );
}
const h = Buffer.alloc(44);
h.write("RIFF");
h.writeUInt32LE(36 + pcm.length, 4);
h.write("WAVE", 8);
h.write("fmt ", 12);
h.writeUInt32LE(16, 16);
h.writeUInt16LE(1, 20);
h.writeUInt16LE(2, 22);
h.writeUInt32LE(sr, 24);
h.writeUInt32LE(sr * 4, 28);
h.writeUInt16LE(4, 32);
h.writeUInt16LE(16, 34);
h.write("data", 36);
h.writeUInt32LE(pcm.length, 40);
fs.writeFileSync(
  new URL("../public/fresh-start.wav", import.meta.url),
  Buffer.concat([h, pcm]),
);
console.log("Original stereo score: 40s, 48 kHz / 16 bit WAV");
