# Cleanly creative studio

Editable Remotion campaign for Cleanly 1.5.2. The production Flutter application is not modified.

- `src/Store.tsx`: 8 phone marketing screenshots, icon, feature graphic, contact sheet.
- `src/scenes/`: six separate video scenes.
- `src/Campaign.tsx`: 40-second sequence and original instrumental.
- `public/`: real Flutter UI captures, existing app fonts, generated room illustration, original soundtrack.
- `scripts/make-score.mjs`: reproducible original synthesized instrumental.
- `scripts/render-assets.mjs`: render all assets and validate PNG measurements.

```sh
npm ci
node scripts/make-score.mjs
npx remotion studio --no-open
node scripts/render-assets.mjs all
```

Outputs: `../store/creative-2026-09/`. No upload or publication step exists.
