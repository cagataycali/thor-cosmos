# Installation

thor-cosmos runs in two places: your **x86 GPU host** (for model prep, training, generation) and your **Jetson AGX Thor** (for edge inference). The package is identical on both — the recipes know which steps only make sense where.

## Prerequisites

- **Python** 3.10+
- **[`just`](https://github.com/casey/just)** — the command runner
- **`git`** — for cloning Cosmos upstream repos
- **AWS / Anthropic / OpenAI / Ollama credentials** — one is enough (the agent auto-detects)

### On Jetson Thor additionally:
- **TensorRT-Edge-LLM** built from source (`llm_build`, `visual_build`, `trt_edgellm_server`)
- **GStreamer** with `nvv4l2decoder` / `nvjpegenc` for HW-accelerated RTP capture
- **NATS** (optional, for perception event publishing)

### On x86 GPU host additionally:
- **`tensorrt-edgellm-*`** CLI tools (for `quantize`, `export-llm`, `export-visual`)
- **`hf`** (`huggingface_hub`) — for model downloads
- **`cosmos-cli` / `cosmos-rl`** — if you plan to post-train Reason2

## Install `just`

=== "macOS"

    ```bash
    brew install just
    ```

=== "Linux"

    ```bash
    curl -LsSf https://get.casey.rs | bash
    # or: cargo install just
    ```

=== "Jetson (L4T)"

    ```bash
    # Use the prebuilt aarch64 binary
    curl -LsSf https://just.systems/install.sh | bash -s -- --to ~/bin
    ```

## Install thor-cosmos

=== "From PyPI"

    ```bash
    pipx install thor-cosmos
    thor-cosmos --help
    ```

=== "From source"

    ```bash
    git clone https://github.com/cagataycali/thor-cosmos
    cd thor-cosmos
    just install       # creates .venv + pip install -e .
    just run           # starts the agent
    ```

## Configure `.env`

Copy the example:

```bash
cp .env.example .env
$EDITOR .env
```

Key variables:

| Variable | Default | Purpose |
|---|---|---|
| `THOR_COSMOS_PROVIDER` | `bedrock` | `bedrock` / `openai` / `ollama` |
| `THOR_COSMOS_MODEL_ID` | `global.anthropic.claude-opus-4-6-v1` | Agent model |
| `COSMOS_PREDICT_REPO` | `../cosmos-predict2.5` | Upstream repo path |
| `COSMOS_TRANSFER_REPO` | `../cosmos-transfer2.5` | Upstream repo path |
| `COSMOS_REASON_REPO` | `../cosmos-reason2` | Upstream repo path |
| `COSMOS_XENNA_REPO` | `../cosmos-xenna` | Upstream repo path |
| `COSMOS_COOKBOOK_REPO` | `../cosmos-cookbook` | Upstream repo path |
| `TRT_ROOT` | `/opt/tensorrt-edge-llm` | TensorRT-LLM build root (Thor only) |
| `VLM_HOST` / `VLM_PORT` | `127.0.0.1` / `8080` | Where the TRT-EdgeLLM server runs |
| `RTP_BIND` / `RTP_PORT` | `0.0.0.0` / `5600` | Camera RTP ingress |
| `NATS_URL` | `nats://127.0.0.1:4222` | Perception event bus |

## Verify

```bash
just env         # shows effective variables
just --list      # shows all 42+ recipes
just smoke       # env + sysinfo + serve-status sanity check
```

If `just smoke` prints no errors, you're ready. [→ Quickstart](quickstart.md)
