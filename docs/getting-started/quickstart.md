# Quickstart

A 2-minute tour. Prerequisites: [installation](installation.md) done.

## 1. Start the agent

```bash
thor-cosmos
# 🤖🌌 thor-cosmos agent — ready
#     model = global.anthropic.claude-opus-4-6-v1
#     tools = 19
#     type 'exit' or Ctrl-C to quit
# 🌌 ▸
```

## 2. Talk to it

```
🌌 ▸ what's the state of the VLM server?
```

The agent calls `cosmos_serve(action="status")` → `just serve-status` → returns `🔴 not running`.

```
🌌 ▸ download Cosmos-Reason2-2B and tell me what it is
```

The agent chains `cosmos_model_download(name="reason2-2b")` with a knowledge lookup.

## 3. Or use `just` directly

Every capability is a shell recipe — the agent and the operator share it:

```bash
just --list
#   default
#   env
#   install
#   run
#   deploy-thor
#   download
#   download-dataset
#   quantize
#   export-llm
#   export-visual
#   ...
#   smoke
```

## 4. Run a real pipeline

### Prep a model on your x86 host
```bash
just prep-edge-model reason2-2b ./models/R2-fp8
# → download from HF
# → quantize to FP8
# → export LLM to ONNX
# → export visual encoder to ONNX
```

### Deploy to Thor
```bash
just deploy-thor cagatay@thor.local ~/thor-cosmos
scp -r ./models/R2-fp8/onnx cagatay@thor.local:~/R2-fp8-onnx
```

### On Thor: build engines + serve
```bash
ssh cagatay@thor.local
cd ~/thor-cosmos
just build-engines ~/R2-fp8-onnx ~/R2-fp8-engines
just serve-start ~/R2-fp8-engines/llm ~/R2-fp8-engines/visual
just serve-status      # 🟢 running pid=1234  http://127.0.0.1:8080
```

### Inference
```bash
just infer assets/test.jpg "count people and describe their clothing"
```

Or through the agent:

```
🌌 ▸ capture a frame from RTP and tell me what you see
```

The agent calls `rtp_capture_frame(...)` → `cosmos_inference(...)` in one turn (the frame bytes are embedded in the first tool result, so the second tool sees the image directly).

## Next

- [Thor deployment](thor-deploy.md) — tmux patterns, persistent services, autostart
- [x86 model prep](x86-prep.md) — quantize, export, distill
- [intbot_edge_vlm walkthrough](../examples/intbot-edge-vlm.md) — the flagship recipe
