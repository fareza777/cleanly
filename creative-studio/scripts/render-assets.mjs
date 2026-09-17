import fs from "node:fs";
import path from "node:path";
import { bundle } from "@remotion/bundler";
import {
  getCompositions,
  openBrowser,
  renderStill,
  renderMedia,
} from "@remotion/renderer";
import sharp from "sharp";
const root = path.resolve("../store/creative-2026-09");
const only = process.argv[2] || "all";
const serveUrl = await bundle({
  entryPoint: path.resolve("src/index.ts"),
  rspack: true,
});
const browser = await openBrowser("chrome");
try {
  const comps = await getCompositions(serveUrl, { puppeteerInstance: browser });
  const common = { serveUrl, puppeteerInstance: browser };
  if (only !== "video") {
    for (const c of comps.filter((c) => c.durationInFrames === 1)) {
      let target;
      if (/^0[1-8]-/.test(c.id)) target = "screenshots/" + c.id + ".png";
      else if (c.id === "Cleanly-Feature")
        target = "brand/feature-graphic-1024x500.png";
      else if (c.id === "Cleanly-Icon") target = "brand/app-icon-512.png";
      else if (c.id === "Cleanly-Icon-Master")
        target = "brand/app-icon-master-1024.png";
      else target = "contact-sheet.png";
      const { buffer } = await renderStill({
        ...common,
        composition: c,
        imageFormat: "png",
      });
      const image = sharp(buffer);
      const output = path.join(root, target);
      fs.mkdirSync(path.dirname(output), { recursive: true });
      // Play requires RGB screenshots/feature graphic and RGBA app icon.
      if (c.id.includes("Icon")) await image.ensureAlpha().png().toFile(output);
      else await image.removeAlpha().png().toFile(output);
      console.log("READY", target);
    }
    const video = comps.find((c) => c.id === "Cleanly-Fresh-Start");
    fs.mkdirSync(path.join(root, "review"), { recursive: true });
    for (const frame of [90, 285, 495, 705, 915, 1110]) {
      await renderStill({
        ...common,
        composition: video,
        frame,
        imageFormat: "jpeg",
        output: path.join(root, "review", `frame-${frame}.jpg`),
      });
    }
  }
  if (only !== "stills") {
    let last = -1;
    await renderMedia({
      ...common,
      composition: comps.find((c) => c.id === "Cleanly-Fresh-Start"),
      codec: "h264",
      crf: 18,
      pixelFormat: "yuv420p",
      audioCodec: "aac",
      audioBitrate: "192k",
      outputLocation: path.join(root, "video/cleanly-fresh-start-1080p.mp4"),
      concurrency: 3,
      onProgress: ({ progress }) => {
        const p = Math.floor(progress * 10);
        if (p !== last) {
          console.log("VIDEO", p * 10 + "%");
          last = p;
        }
      },
    });
  }
  const manifest = [];
  for (const dir of ["screenshots", "brand"])
    for (const name of fs.readdirSync(path.join(root, dir))) {
      const filename = path.join(root, dir, name);
      const meta = await sharp(filename).metadata();
      manifest.push({
        file: dir + "/" + name,
        width: meta.width,
        height: meta.height,
        channels: meta.channels,
        bytes: fs.statSync(filename).size,
      });
    }
  fs.writeFileSync(
    path.join(root, "asset-validation.json"),
    JSON.stringify(manifest, null, 2),
  );
} finally {
  await browser.close({ silent: true });
}
