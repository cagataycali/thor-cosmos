# Changelog

All notable changes to **thor-cosmos** are tracked here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Full MkDocs Material documentation site (`docs/`) with animated hero logo.
- Standalone landing page (`web/index.html`) with SEO + OG tags.
- GitHub Actions workflows: `docs.yml`, `auto-release.yml`, `ci.yml`, `build.yml`.
- `docs/assets/thor-animated.svg` — animated hero logo (NVIDIA-green gradient).
- `docs/architecture.md` — justfile-as-API diagram.
- `docs/api-reference.md` — all 19 tools with parameters.
- Guide pages for every tool family: Reason2, Predict2.5, Transfer2.5, Xenna,
  Training & Distillation, Evaluation (12 metrics).
- Example walkthroughs: `intbot_edge_vlm`, `gr00t-dreams`, `perception-loop`.
- `CONTRIBUTING.md` and this `CHANGELOG.md`.

### Changed
- Rewrote `README.md` with badge row, animated hero, ASCII architecture,
  tool table, and quickstart.

## [0.1.0] — initial

### Added
- Core `justfile` with 42 recipes covering the full Cosmos lifecycle.
- 19 Strands tools across Reason2 / Predict2.5 / Transfer2.5 / Xenna / I/O.
- `AGENTS.md` — guidance for AI agents operating in-repo.
- Pipeline recipes: `prep-edge-model`, `pipeline-edge-deploy`,
  `pipeline-gr00t-dreams`, `perception-loop`, `deploy-thor`, `smoke`.
