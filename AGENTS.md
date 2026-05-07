# AGENTS.md

> Guidance for AI agents (Claude, devduck, thor-cosmos itself) operating in this repo.

## 🎯 What this repo is

**thor-cosmos** is a Strands agent + `justfile` that orchestrates the **NVIDIA Cosmos ecosystem** (Reason2 VLM, Predict2.5 world model, Transfer2.5 ControlNet, Xenna data curation) for deployment on **Jetson AGX Thor** edge hardware.

**Primary use case**: real-time VLM perception on a robot (see cookbook `intbot_edge_vlm`).
**Secondary use cases**: synthetic trajectory generation, video generation with style/structure control, model post-training, distillation.

## 🏗 Architecture: one source of truth

```
   Operator CLI         Strands Agent
        │                     │
        │  just <recipe>      │  cosmos_*()
        │                     │     │
        └─────────────────────┴─────┘
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

**Rule #1**: if you need to run a command, it **must** exist as a `just` recipe. Don't inline shell calls in Python.

## 📁 Directory layout

```
thor-cosmos/
├── justfile              ← 42 recipes — the command surface
├── pyproject.toml        ← entry point: `thor-cosmos`
├── thor_cosmos/
│   ├── agent.py          ← while True: agent(input()) loop
│   └── tools/
│       ├── _common.py    ← ok() / err() / just_run() helpers
│       ├── inference.py  ← cosmos_inference (direct HTTP, not via just)
│       ├── serve.py      ← thin wrapper → just serve-*
│       ├── quantize.py   ← thin wrapper → just quantize
│       ├── ...           ← (all other tools, same pattern)
├── .env.example          ← copy to .env; `just` auto-loads it
├── configs/
│   └── robot-vlm-client.example.yaml
└── AGENTS.md             ← you are here
```

## 🧰 The toolkit (19 tools, 4 families)

| Family | Tools | Recipe prefix |
|--------|-------|---------------|
| **Reason2 (VLM)** | `cosmos_inference`, `cosmos_reason_hf`, `cosmos_serve`, `cosmos_quantize`, `cosmos_export_onnx`, `cosmos_build_engine` | `serve-*`, `quantize`, `export-llm`, `export-visual`, `build-*-engine`, `infer` |
| **Predict2.5 (world model)** | `cosmos_predict_generate`, `cosmos_post_train`, `cosmos_distill` | `predict-generate`, `post-train-predict`, `distill` |
| **Transfer2.5 (ControlNet)** | `cosmos_transfer_generate`, `cosmos_post_train`, `cosmos_distill` | `transfer-generate`, `post-train-transfer`, `distill` |
| **Xenna + eval** | `cosmos_curate`, `cosmos_evaluate` | `curate`, `evaluate` |
| **I/O + utils** | `rtp_capture_frame`, `nats_publish`, `cosmos_model_download`, `video_probe`, `video_extract_frames`, `image_read`, `system_info` | `rtp-capture`, `nats-publish`, `download*`, `video-*`, `sysinfo` |

## 📡 The `ToolResult` contract

Every `@tool`-decorated function returns:

```python
{
    "status": "success" | "error",
    "content": [
        {"text": "human-readable summary"},                           # always
        {"json": {...structured data...}},                            # optional
        {"image": {"format": "jpeg", "source": {"bytes": b"..."}}},   # optional
    ],
}
```

**Use `ok()` and `err()` from `tools/_common.py`** — never build this dict by hand.

**Image-producing tools** (`rtp_capture_frame`, `video_extract_frames`, `image_read`) **MUST embed the JPEG bytes** in the response so the agent can feed them straight into `cosmos_inference` on the next turn. No "save to disk then tell agent the path" anti-pattern.

## ⚡ How to add a new tool (follow the pattern)

**1. Add a recipe to `justfile`** (single source of truth for the command):

```justfile
# One-line description for `just --list`
my-new-thing arg1 arg2="default_value":
    some-cli --foo "{{arg1}}" --bar "{{arg2}}"
```

**2. Create `thor_cosmos/tools/my_new_thing.py`** as a thin wrapper:

```python
"""Wrapper around `just my-new-thing`."""
from __future__ import annotations

from strands import tool
from ._common import just_run, proc_result


@tool
def my_new_thing(arg1: str, arg2: str = "default") -> dict:
    """One-line description, then what it does.

    Args:
        arg1: what arg1 means.
        arg2: what arg2 means.
    """
    proc = just_run("my-new-thing", arg1, arg2, timeout_s=60 * 10)
    return proc_result(
        proc,
        success_text=f"✅ did the thing with {arg1}",
        fail_text=f"failed: {proc.get('stderr', '')[:200]}",
    )
```

**3. Register it in `thor_cosmos/tools/__init__.py`**:

```python
from thor_cosmos.tools.my_new_thing import my_new_thing
__all__ = [..., "my_new_thing"]
```

**4. Register it in `thor_cosmos/agent.py`** inside `build_agent()`:

```python
return Agent(
    model=model,
    system_prompt=SYSTEM_PROMPT,
    tools=[..., my_new_thing],
)
```

**5. Verify**:
```bash
python3 -c "import ast; ast.parse(open('thor_cosmos/tools/my_new_thing.py').read())"
just --list | grep my-new-thing
just my-new-thing some_arg        # smoke test
```

## 🎭 Environment & configuration

All recipes honor these env vars (`dotenv-load` is on — put them in `.env`):

| Var | Default | Purpose |
|-----|---------|---------|
| `THOR_COSMOS_PROVIDER` | `bedrock` | `bedrock` / `openai` / `ollama` |
| `THOR_COSMOS_MODEL_ID` | `global.anthropic.claude-opus-4-6-v1` | model for the agent |
| `COSMOS_PREDICT_REPO` | `../cosmos-predict2.5` | path to cosmos-predict2.5 clone |
| `COSMOS_TRANSFER_REPO` | `../cosmos-transfer2.5` | path to cosmos-transfer2.5 clone |
| `COSMOS_REASON_REPO` | `../cosmos-reason2` | path to cosmos-reason2 clone |
| `COSMOS_XENNA_REPO` | `../cosmos-xenna` | path to cosmos-xenna clone |
| `COSMOS_COOKBOOK_REPO` | `../cosmos-cookbook` | path to cosmos-cookbook clone |
| `TRT_ROOT` | `/opt/tensorrt-edge-llm` | TensorRT-LLM build root (Thor) |
| `COSMOS_SERVER_BIN` | `$TRT_ROOT/build/examples/server/trt_edgellm_server` | serve binary |
| `TRT_LLM_BUILD_BIN` | `$TRT_ROOT/build/examples/llm/llm_build` | engine-build binary |
| `TRT_VISUAL_BUILD_BIN` | `$TRT_ROOT/build/examples/multimodal/visual_build` | visual-engine-build binary |
| `VLM_HOST`/`VLM_PORT` | `127.0.0.1`/`8080` | where the TRT-EdgeLLM server runs |
| `RTP_BIND`/`RTP_PORT` | `0.0.0.0`/`5600` | camera RTP ingress |
| `NATS_URL` | `nats://127.0.0.1:4222` | perception event bus |

## 🚀 Pipelines (composed recipes)

These meta-recipes chain multiple atomic recipes. Prefer them when the operator asks for an end-to-end flow:

| Recipe | What it does |
|--------|--------------|
| `just prep-edge-model <model> <out>` | download → quantize (fp8) → export-llm → export-visual |
| `just pipeline-edge-deploy <model> <out>` | intbot_edge_vlm full chain (with Thor handoff hints) |
| `just pipeline-gr00t-dreams <dataset> <config>` | download → post-train-predict |
| `just perception-loop <subject> <prompt>` | continuous capture → infer → nats-publish (run in tmux) |
| `just deploy-thor <ssh> <dest>` | rsync this repo to Thor + run `just install` |
| `just smoke` | env + sysinfo + serve-status (sanity check) |

## 🚧 Common workflows

### Deploy thor-cosmos to Thor (rsync + tmux)

```bash
# From your laptop:
just deploy-thor cagatay@thor.local ~/thor-cosmos

# On Thor (interactive agent in tmux):
tmux new -s thor 'cd ~/thor-cosmos && just run'
# Detach: Ctrl-B D.  Reattach: tmux a -t thor
```

### Deploy Cosmos-Reason2 to Thor (intbot_edge_vlm)

```bash
# On x86 GPU host:
just prep-edge-model reason2-2b ./models/R2-fp8
scp -r ./models/R2-fp8/onnx thor:~/R2-fp8-onnx

# On Thor:
just build-engines ~/R2-fp8-onnx ~/R2-fp8-engines
just serve-start ~/R2-fp8-engines/llm ~/R2-fp8-engines/visual
just infer /path/to/test.jpg "count people in scene"
```

### Real-time perception loop

```bash
# Thor, server running. Inside tmux:
just perception-loop perception.vlm "describe the scene, count people"
# Loops capture→infer→nats-publish until Ctrl-C.
# Or do one shot manually:
just rtp-capture                    # saves /tmp/thor_cosmos_perception.jpg
just infer /tmp/thor_cosmos_perception.jpg "describe the scene"
just nats-publish perception.vlm '{"text": "..."}'
```

### Synthetic trajectory generation (GR00T-Dreams)

```bash
just download-dataset gr1
just post-train-predict configs/gr00t-dreams.yaml 8
just predict-generate inputs/video2world.json
just evaluate reason_critic ./outputs/predict2_5 ./ground-truth
```

## 🐛 Troubleshooting / gotchas

1. **`just: command not found`** → `brew install just` or `curl -LsSf https://get.casey.rs | bash`
2. **Cosmos repos not found** → Set `COSMOS_*_REPO` env vars or clone alongside thor-cosmos. `just env` prints effective paths.
3. **TRT binaries missing on Thor** → Build TensorRT-LLM from source first. The cudnn:9.12.0 KeyError in jetson-containers is a known upstream issue — pin to a working CuDNN version or build without jetson-containers.
4. **`cosmos_inference` says "cannot reach VLM server"** → `just serve-status` → if 🔴, run `just serve-start <llm_engines> <visual_engines>`.
5. **`rtp_capture_frame` timeout** → Check `RTP_BIND` matches the interface the camera sends to; try `hw_decode=False` in the tool call (auto-fallback already handles this).
6. **Tool returns a path but not image bytes** → you're using an older version; check `_common.py` has `just_run` + `ok()` takes `image_bytes` param.

## 🧠 How to reason about tasks

When the operator gives a new request:

1. **Is there already a `just` recipe?** → `just --list` (and use the tool that wraps it).
2. **Does it need a new recipe?** → add to `justfile` first, then wrap in a tool.
3. **Does it need a new pipeline?** → compose existing recipes into a new one in `justfile` (under `## ── Pipelines ──`).
4. **Does it need a new model family?** → unlikely — Cosmos has 4 (Reason2, Predict2.5, Transfer2.5, Xenna). If new, follow the existing family pattern.

**Parallelism**: the agent's rule of batching independent tool calls applies here too. For pipelines with independent steps (e.g. quantize LLM + download dataset), fire them in parallel.

## 📜 Code style

- **Python**: 3.10+, type-hinted, `from __future__ import annotations` at the top.
- **Line length**: 100.
- **Imports**: stdlib → 3rd-party → local (`._common`).
- **Error handling**: never `raise` in a tool — always return `err(...)`. The agent needs a result, not a crash.
- **Docstrings**: one-line summary → args (Google style). The LLM reads these to know how to call the tool.
- **No emojis in code** (ok in `text` output for user visibility).
- **No secrets** in committed code — always via env vars.

## 🤝 Interacting with upstream Cosmos repos

When a tool needs to run *inside* a Cosmos repo (e.g. `python examples/inference.py`):

- The `justfile` uses `cd "{{repo}}"` then runs the upstream repo's `just run` (they all have it).
- This means upstream's venv + uv sync is handled for us — we never `pip install` their deps.
- Pass repo paths via env (`COSMOS_PREDICT_REPO`, etc.), not hardcoded.

## 🔁 Self-modification guidance

If you (an agent) realize a tool is missing or wrong:

1. **Open the justfile first** — add/fix the recipe.
2. Make the Python wrapper dumber, not smarter. Recipes hold logic; Python normalizes results.
3. Test with `just <recipe> <args>` on the command line before wiring the tool.
4. If a recipe grows too complex, split it into an atomic recipe + a pipeline recipe.
5. Commit with a clear message: `feat: add <recipe>` or `fix: <recipe> handles <edge case>`.

## 📚 References (cookbook recipes this repo implements)

- **[intbot_edge_vlm](https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/inference/reason2/intbot_edge_vlm/inference.html)** — primary flagship recipe for Jetson Thor edge VLM
- **[gr00t-dreams](https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/end2end/gr00t-dreams/post-training.html)** — synthetic trajectory generation
- **[worker_safety](https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/inference/reason2/worker_safety/inference.html)** — zero-shot VQA
- **[image-prompt transfer](https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/inference/transfer2_5/inference-image-prompt/inference.html)** — style-guided video generation
- **[Cosmos data curation](https://nvidia-cosmos.github.io/cosmos-cookbook/core_concepts/data_curation/overview.html)** — Xenna 7-stage pipeline
- **[Cosmos evaluation](https://nvidia-cosmos.github.io/cosmos-cookbook/core_concepts/evaluation/overview.html)** — FID/FVD/TSE/CSE/Sampson/Reason-as-reward

## 🪄 TL;DR for a new agent

```
1. `just --list`             — see what's available
2. `just env`                — check your environment
3. `just smoke`              — sanity-check the install
4. Operator says X → is there a recipe? → yes: call the tool → no: add recipe first.
5. Never inline commands in Python. Recipes are the truth.
6. Return rich ToolResults (text + json + image where relevant).
7. Parallelize independent calls.
```
