<div align="center">
  <img src="docs/assets/thor-animated.svg" width="180" alt="thor-cosmos">
  <h1>thor-cosmos</h1>
  <p><em>NVIDIA Cosmos on Jetson AGX Thor — one <code>justfile</code>, one Strands agent, full lifecycle.</em></p>
  <p>
    <a href="https://pypi.org/project/thor-cosmos/"><img alt="PyPI" src="https://img.shields.io/pypi/v/thor-cosmos?color=76b900&style=flat-square"></a>
    <a href="https://python.org"><img alt="Python" src="https://img.shields.io/badge/python-3.10+-76b900?style=flat-square"></a>
    <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-76b900?style=flat-square"></a>
    <a href="https://github.com/cagataycali/awesome-strands-agents"><img alt="Awesome Strands Agents" src="https://img.shields.io/badge/Awesome-Strands%20Agents-00FF77?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjkwIiBoZWlnaHQ9IjQ2MyIgdmlld0JveD0iMCAwIDI5MCA0NjMiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxwYXRoIGQ9Ik05Ny4yOTAyIDUyLjc4ODRDODUuMDY3NCA0OS4xNjY3IDcyLjIyMzQgNTYuMTM4OSA2OC42MDE3IDY4LjM2MTZDNjQuOTgwMSA4MC41ODQzIDcxLjk1MjQgOTMuNDI4MyA4NC4xNzQ5IDk3LjA1MDFMMjM1LjExNyAxMzkuNzc1QzI0NS4yMjMgMTQyLjc2OSAyNDYuMzU3IDE1Ni42MjggMjM2Ljg3NCAxNjEuMjI2TDMyLjU0NiAyNjAuMjkxQy0xNC45NDM5IDI4My4zMTYgLTkuMTYxMDcgMzUyLjc0IDQxLjQ4MzUgMzY3LjU5MUwxODkuNTUxIDQxMS4wMDlMMTkwLjEyNSA0MTEuMTY5QzIwMi4xODMgNDE0LjM3NiAyMTQuNjY1IDQwNy4zOTYgMjE4LjE5NiAzOTUuMzU1QzIyMS43ODQgMzgzLjEyMiAyMTQuNzc0IDM3MC4yOTYgMjAyLjU0MSAzNjYuNzA5TDU0LjQ3MzggMzIzLjI5MUM0NC4zNDQ3IDMyMC4zMjEgNDMuMTg3OSAzMDYuNDM2IDUyLjY4NTcgMzAxLjgzMUwyNTcuMDE0IDIwMi43NjZDMzA0LjQzMiAxNzkuNzc2IDI5OC43NTggMTEwLjQ4MyAyNDguMjMzIDk1LjUxMkw5Ny4yOTAyIDUyLjc4ODRaIiBmaWxsPSIjRkZGRkZGIi8+CjxwYXRoIGQ9Ik0yNTkuMTQ3IDAuOTgxODEyQzI3MS4zODkgLTIuNTc0OTggMjg0LjE5NyA0LjQ2NTcxIDI4Ny43NTQgMTYuNzA3NEMyOTEuMzExIDI4Ljk0OTIgMjg0LjI3IDQxLjc1NyAyNzIuMDI4IDQ1LjMxMzhMNzEuMTcyNyAxMDMuNjcxQzQwLjcxNDIgMTEyLjUyMSAzNy4xOTc2IDE1NC4yNjIgNjUuNzQ1OSAxNjguMDgzTDI0MS4zNDMgMjUzLjA5M0MzMDcuODcyIDI4NS4zMDIgMjk5Ljc5NCAzODIuNTQ2IDIyOC44NjIgNDAzLjMzNkwzMC40MDQxIDQ2MS41MDJDMTguMTcwNyA0NjUuMDg4IDUuMzQ3MDggNDU4LjA3OCAxLjc2MTUzIDQ0NS44NDRDLTEuODIzOSA0MzMuNjExIDUuMTg2MzcgNDIwLjc4NyAxNy40MTk3IDQxNy4yMDJMMjE1Ljg3OCAzNTkuMDM1QzI0Ni4yNzcgMzUwLjEyNSAyNDkuNzM5IDMwOC40NDkgMjIxLjIyNiAyOTQuNjQ1TDQ1LjYyOTcgMjA5LjYzNUMtMjAuOTgzNCAxNzcuMzg2IC0xMi43NzcyIDc5Ljk4OTMgNTguMjkyOCA1OS4zNDAyTDI1OS4xNDcgMC45ODE4MTJaIiBmaWxsPSIjRkZGRkZGIi8+Cjwvc3ZnPgo=&logoColor=white)](https://github.com/cagataycali/awesome-strands-agents"></a>
    <a href="https://cagataycali.github.io/thor-cosmos/"><img alt="Docs" src="https://img.shields.io/badge/docs-mkdocs--material-76b900?style=flat-square"></a>
  </p>
</div>

---

**thor-cosmos** is a Strands agent + `justfile` that orchestrates the full NVIDIA Cosmos ecosystem and deploys it on **Jetson AGX Thor** for real-time robot perception.

Wraps **Cosmos-Reason2** (VLM), **Cosmos-Predict2.5** (world model), **Cosmos-Transfer2.5** (ControlNet), and **Cosmos-Xenna** (data curation) — every pipeline is a `just` recipe that agents *and* operators share.

```
 Operator CLI         Strands Agent
      │                     │
      │  just <recipe>      │  cosmos_*()
      │                     │
      └─────────────────────┴─────────┐
                                      ▼
                              ┌───────────────┐
                              │   justfile    │  ← EVERYTHING lives here
                              │  (42 recipes) │
                              └───────────────┘
                                      │
                      ┌───────────────┼───────────────┐
                      ▼               ▼               ▼
               tensorrt-edgellm-*   torchrun     curl/gst/nats
               (quant/export)      (train/distill) (serve/io)
```

---

## Why the `justfile` pattern?

- **Same muscle memory as upstream**: every Cosmos repo (`cosmos-predict2.5`, `cosmos-transfer2.5`, `cosmos-reason2`, `cosmos-cookbook`) already ships a `justfile`. Ours blends in.
- **One source of truth**: agents shell out to `just <recipe>`; operators run `just <recipe>` directly. Zero duplication.
- **Thin Python tools**: each `@tool` is ~30 lines that invokes a recipe and maps output → Strands `ToolResult`.
- **Discoverable**: `just --list` prints every pipeline step.
- **Composable**: `pipeline-edge-deploy` chains `download → quantize → export-llm → export-visual`.

---

## Installation

```bash
brew install just                         # (or: curl -LsSf https://get.casey.rs | bash)
pipx install thor-cosmos
thor-cosmos                               # start the agent
```

From source:

```bash
git clone https://github.com/cagataycali/thor-cosmos
cd thor-cosmos
just install                              # venv + pip install -e .
just run                                  # start agent REPL
```

On Jetson Thor (rsync from laptop, run via tmux):

```bash
# From your laptop:
just deploy-thor cagatay@thor.local ~/thor-cosmos

# On Thor:
ssh cagatay@thor.local
tmux new -s thor 'cd ~/thor-cosmos && just run'
```

---

## Tools ↔ Recipes

| Tool (agent) | `just` recipe (CLI) |
|---|---|
| `cosmos_model_download` | `just download <name>` / `just download-dataset <name>` |
| `cosmos_quantize` | `just quantize <model_dir> <output_dir> <dtype> <quantization>` |
| `cosmos_export_onnx` (llm) | `just export-llm <model_dir> <output_dir>` |
| `cosmos_export_onnx` (visual) | `just export-visual <model_dir> <output_dir> <dtype> <quant>` |
| `cosmos_build_engine` (llm) | `just build-llm-engine <onnx_dir> <engine_dir> ...` |
| `cosmos_build_engine` (visual) | `just build-visual-engine <onnx_dir> <engine_dir>` |
| `cosmos_serve(start\|stop\|status\|logs\|restart)` | `serve-start` / `serve-stop` / `serve-status` / `serve-logs` / `serve-restart` |
| `cosmos_inference` | `just infer <image> <prompt>` |
| `cosmos_reason_hf` | HF Transformers direct (no recipe) |
| `rtp_capture_frame` | `just rtp-capture <port> <out> <w> <h> <timeout>` |
| `nats_publish` | `just nats-publish <subject> <payload_json>` |
| `cosmos_predict_generate` | `just predict-generate <input.json>` |
| `cosmos_transfer_generate` | `just transfer-generate <input.json> <control>` |
| `cosmos_post_train(reason2\|predict2_5\|transfer2_5)` | `post-train-reason2` / `post-train-predict` / `post-train-transfer` |
| `cosmos_distill` | `just distill <teacher> <student> <method> <family>` |
| `cosmos_curate` | `just curate <input> <output> <stages>` |
| `cosmos_evaluate` | `just evaluate <metric> <pred> <gt>` |
| `system_info` | `just sysinfo` |
| `video_probe` / `video_extract_frames` | `just video-probe` / `just video-frames` |
| `image_read` | — (read + embed JPEG bytes) |

---

## Pipelines (composed recipes)

```bash
# Full x86 model prep (download → quantize → export-llm → export-visual)
just prep-edge-model reason2-2b ./models/Cosmos-Reason2-2B-fp8

# Flagship edge deployment (intbot_edge_vlm)
just pipeline-edge-deploy reason2-2b ./models/Cosmos-Reason2-2B-fp8

# GR00T-Dreams synthetic trajectories
just pipeline-gr00t-dreams ./datasets/gr1 configs/gr00t-dreams.yaml

# Real-time perception (RTP → VLM → NATS, runs in tmux)
just perception-loop perception.vlm "describe the scene, count people"

# Smoke test
just smoke
```

---

## The flagship recipe — `intbot_edge_vlm`

Deploy Cosmos-Reason2 to Thor for real-time robot perception.

```bash
# On x86 GPU host
just prep-edge-model reason2-2b ./models/R2-fp8
scp -r ./models/R2-fp8/onnx cagatay@thor.local:~/R2-fp8-onnx

# On Thor
just build-engines ~/R2-fp8-onnx ~/R2-fp8-engines
just serve-start ~/R2-fp8-engines/llm ~/R2-fp8-engines/visual
just infer /tmp/test.jpg "count people in the scene"

# Continuous loop
just perception-loop perception.vlm "describe the scene; count people"
```

Expected throughput on Jetson AGX Thor with Cosmos-Reason2-2B FP8: **3-5 FPS** at 800×600 and 128-token output.

→ [Full walkthrough in the docs](https://cagataycali.github.io/thor-cosmos/examples/intbot-edge-vlm/)

---

## Environment

All `just` recipes honor these env vars (put them in `.env` — `dotenv-load` is on):

```bash
# Agent model
THOR_COSMOS_PROVIDER=bedrock              # bedrock | openai | ollama
THOR_COSMOS_MODEL_ID=global.anthropic.claude-opus-4-6-v1
AWS_REGION=us-west-2

# TRT-Edge-LLM binaries (Thor)
TRT_ROOT=/opt/tensorrt-edge-llm
COSMOS_SERVER_BIN=${TRT_ROOT}/build/examples/server/trt_edgellm_server
TRT_LLM_BUILD_BIN=${TRT_ROOT}/build/examples/llm/llm_build
TRT_VISUAL_BUILD_BIN=${TRT_ROOT}/build/examples/multimodal/visual_build

# Cosmos upstream repo paths (cloned alongside thor-cosmos by default)
COSMOS_PREDICT_REPO=../cosmos-predict2.5
COSMOS_TRANSFER_REPO=../cosmos-transfer2.5
COSMOS_REASON_REPO=../cosmos-reason2
COSMOS_XENNA_REPO=../cosmos-xenna
COSMOS_RL_REPO=../cosmos-rl
COSMOS_COOKBOOK_REPO=../cosmos-cookbook

# Serve / IO
VLM_HOST=127.0.0.1
VLM_PORT=8080
RTP_BIND=0.0.0.0
RTP_PORT=5600
NATS_URL=nats://127.0.0.1:4222
```

---

## `ToolResult` contract

Every tool returns:

```python
{
    "status": "success" | "error",
    "content": [
        {"text": "..."},                                          # human-readable
        {"json": {...}},                                          # structured payload
        {"image": {"format": "jpeg", "source": {"bytes": b"..."}}},
    ],
}
```

Image-producing tools (`rtp_capture_frame`, `video_extract_frames`, `image_read`) **embed the captured JPEG bytes** so the agent can feed them straight into `cosmos_inference` on the next turn — no disk round-trip.

---

## Docs

- **[Installation](https://cagataycali.github.io/thor-cosmos/getting-started/installation/)** — prerequisites, env setup, verify
- **[Quickstart](https://cagataycali.github.io/thor-cosmos/getting-started/quickstart/)** — 2-minute tour
- **[Thor deployment](https://cagataycali.github.io/thor-cosmos/getting-started/thor-deploy/)** — rsync, tmux, systemd
- **[x86 model prep](https://cagataycali.github.io/thor-cosmos/getting-started/x86-prep/)** — quantize, export, ship
- **[Architecture](https://cagataycali.github.io/thor-cosmos/architecture/)** — justfile-as-API pattern
- **[API reference](https://cagataycali.github.io/thor-cosmos/api-reference/)** — all 19 tools
- **[intbot_edge_vlm](https://cagataycali.github.io/thor-cosmos/examples/intbot-edge-vlm/)** — flagship walkthrough

Landing page: **[cagataycali.github.io/thor-cosmos](https://cagataycali.github.io/thor-cosmos/)**

---

## References

- [Cosmos Cookbook](https://nvidia-cosmos.github.io/cosmos-cookbook/) — upstream recipes
- [Cosmos-Reason2](https://github.com/nvidia-cosmos/cosmos-reason2)
- [Cosmos-Predict2.5](https://github.com/nvidia-cosmos/cosmos-predict2.5)
- [Cosmos-Transfer2.5](https://github.com/nvidia-cosmos/cosmos-transfer2.5)
- [Cosmos-Xenna](https://github.com/nvidia-cosmos/cosmos-xenna)
- [Strands Agents](https://strandsagents.com)

---

<div align="center">
  <sub>Apache-2.0 · built for Physical AI · <a href="https://github.com/cagataycali/thor-cosmos">GitHub</a></sub>
</div>
