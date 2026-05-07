# Deploying to Jetson AGX Thor

## One-shot deployment from laptop

`deploy-thor` rsyncs the repo, then runs `just install` on the target:

```bash
just deploy-thor cagatay@thor.local ~/thor-cosmos
```

Excluded paths (won't rsync): `.venv/`, `.git/`, `__pycache__`, `outputs/`, `checkpoints/`, `datasets/`, `models/`, `engines/`, `onnx_models/`, `.env`.

## Persistent agent (tmux)

```bash
ssh cagatay@thor.local
tmux new -s thor 'cd ~/thor-cosmos && just run'
# Detach: Ctrl-B D
# Reattach: tmux a -t thor
```

## TRT-Edge-LLM prerequisites

Build the three required binaries on Thor (once):

```bash
# clone and build tensorrt-edge-llm — see upstream README
export TRT_ROOT=/opt/tensorrt-edge-llm
ls $TRT_ROOT/build/examples/server/trt_edgellm_server
ls $TRT_ROOT/build/examples/llm/llm_build
ls $TRT_ROOT/build/examples/multimodal/visual_build
```

Set in `.env`:

```bash
TRT_ROOT=/opt/tensorrt-edge-llm
COSMOS_SERVER_BIN=${TRT_ROOT}/build/examples/server/trt_edgellm_server
TRT_LLM_BUILD_BIN=${TRT_ROOT}/build/examples/llm/llm_build
TRT_VISUAL_BUILD_BIN=${TRT_ROOT}/build/examples/multimodal/visual_build
```

## Build engines

```bash
just build-engines ~/R2-fp8-onnx ~/R2-fp8-engines
# → build-llm-engine    (max_image_tokens=10240, max_input_len=1024)
# → build-visual-engine
```

## Serve + verify

```bash
just serve-start ~/R2-fp8-engines/llm ~/R2-fp8-engines/visual
just serve-status       # 🟢 running pid=...  http://127.0.0.1:8080
just serve-logs 40      # tail
just infer /tmp/frame.jpg "describe the scene"
```

## Real-time perception loop

```bash
tmux new -s perception
just perception-loop perception.vlm "count people, report clothing"
# Ctrl-C to stop, Ctrl-B D to detach
```

Loops: RTP capture → VLM infer → NATS publish.

## RTP camera setup

Any H.264 RTP sender works. Quick test from the robot side:

```bash
gst-launch-1.0 -v videotestsrc ! x264enc tune=zerolatency ! rtph264pay ! \
  udpsink host=<thor-ip> port=5600
```

On Thor side, `rtp_capture_frame` uses the Jetson HW decoder (`nvv4l2decoder` + `nvjpegenc`) and falls back to `avdec_h264` + `jpegenc` if unavailable.

## Diagnostics

```bash
just sysinfo
# --- jetson ---
# NVIDIA Jetson AGX Thor
# --- nvidia-smi ---
# ...
# --- thermal ---
# CPU: 45.2C
# GPU: 48.1C
# --- nvpmodel ---
# NV Power Mode: MAXN_SUPER
```

## Autostart (systemd)

See [`systemd/thor-cosmos.service`](https://github.com/cagataycali/thor-cosmos) for a sample unit file.
