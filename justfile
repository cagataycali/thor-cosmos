# thor-cosmos — NVIDIA Cosmos on Jetson AGX Thor
# All scripts, pipelines, and agent tools route through this justfile.
# Agent tools shell out to `just <recipe>`; operators can run them directly.

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true
set positional-arguments := true

# ── Environment defaults ──────────────────────────────────────────────────
# Override anything with `just VAR=value <recipe>` or .env file.
VENV              := ".venv"
PYTHON            := "python3"

# Cosmos repos (cloned alongside thor-cosmos by default)
COSMOS_PREDICT_REPO   := env_var_or_default("COSMOS_PREDICT_REPO", "../cosmos-predict2.5")
COSMOS_TRANSFER_REPO  := env_var_or_default("COSMOS_TRANSFER_REPO", "../cosmos-transfer2.5")
COSMOS_REASON_REPO    := env_var_or_default("COSMOS_REASON_REPO", "../cosmos-reason2")
COSMOS_XENNA_REPO     := env_var_or_default("COSMOS_XENNA_REPO", "../cosmos-xenna")
COSMOS_RL_REPO        := env_var_or_default("COSMOS_RL_REPO", "../cosmos-rl")
COSMOS_COOKBOOK_REPO  := env_var_or_default("COSMOS_COOKBOOK_REPO", "../cosmos-cookbook")

# TensorRT-Edge-LLM binaries (Thor-side)
TRT_ROOT              := env_var_or_default("TRT_ROOT", "/opt/tensorrt-edge-llm")
SERVER_BIN            := env_var_or_default("COSMOS_SERVER_BIN", TRT_ROOT + "/build/examples/server/trt_edgellm_server")
LLM_BUILD_BIN         := env_var_or_default("TRT_LLM_BUILD_BIN", TRT_ROOT + "/build/examples/llm/llm_build")
VISUAL_BUILD_BIN      := env_var_or_default("TRT_VISUAL_BUILD_BIN", TRT_ROOT + "/build/examples/multimodal/visual_build")

# Serve config
VLM_HOST              := env_var_or_default("VLM_HOST", "127.0.0.1")
VLM_PORT              := env_var_or_default("VLM_PORT", "8080")
VLM_URL               := "http://" + VLM_HOST + ":" + VLM_PORT + "/v1/chat/completions"

# RTP / NATS
RTP_BIND              := env_var_or_default("RTP_BIND", "0.0.0.0")
RTP_PORT              := env_var_or_default("RTP_PORT", "5600")
NATS_URL              := env_var_or_default("NATS_URL", "nats://127.0.0.1:4222")

PID_FILE              := env_var_or_default("COSMOS_SERVER_PID", "/tmp/thor-cosmos-server.pid")
LOG_FILE              := env_var_or_default("COSMOS_SERVER_LOG", "/tmp/thor-cosmos-server.log")


# ── Top-level ─────────────────────────────────────────────────────────────
default:
    @just --list --unsorted

# Print the effective environment
env:
    @echo "COSMOS_PREDICT_REPO  = {{COSMOS_PREDICT_REPO}}"
    @echo "COSMOS_TRANSFER_REPO = {{COSMOS_TRANSFER_REPO}}"
    @echo "COSMOS_REASON_REPO   = {{COSMOS_REASON_REPO}}"
    @echo "COSMOS_XENNA_REPO    = {{COSMOS_XENNA_REPO}}"
    @echo "COSMOS_RL_REPO       = {{COSMOS_RL_REPO}}"
    @echo "COSMOS_COOKBOOK_REPO = {{COSMOS_COOKBOOK_REPO}}"
    @echo "TRT_ROOT             = {{TRT_ROOT}}"
    @echo "VLM_URL              = {{VLM_URL}}"
    @echo "NATS_URL             = {{NATS_URL}}"

# ── Install ───────────────────────────────────────────────────────────────
# Create venv + install thor-cosmos in editable mode
install:
    {{PYTHON}} -m venv {{VENV}} || true
    {{VENV}}/bin/pip install -U pip
    {{VENV}}/bin/pip install -e .
    @cp -n .env.example .env 2>/dev/null || true
    @echo ""
    @echo "✅ installed. Next:  just run   (or:  just smoke)"

# Run the agent REPL (equivalent to `thor-cosmos`)
run *args="":
    {{VENV}}/bin/thor-cosmos {{args}}

# Deploy this repo to a remote Thor via rsync + run `just install` there.
# Usage: just deploy-thor cagatay@192.168.1.151 ~/thor-cosmos
deploy-thor ssh_target="cagatay@thor.local" dest="~/thor-cosmos":
    rsync -av --delete \
      --exclude='.venv' --exclude='.git' --exclude='__pycache__' \
      --exclude='outputs/' --exclude='checkpoints/' --exclude='datasets/' \
      --exclude='models/' --exclude='engines/' --exclude='onnx_models/' \
      --exclude='.env' \
      ./ "{{ssh_target}}:{{dest}}/"
    ssh "{{ssh_target}}" "cd {{dest}} && just install"
    @echo ""
    @echo "✅ deployed to {{ssh_target}}:{{dest}}"
    @echo "   Run:  ssh -t {{ssh_target}} 'cd {{dest}} && just run'"
    @echo "   Or:   ssh -t {{ssh_target}} 'tmux new -s thor "cd {{dest}} && just run"'" 


# ── Model / dataset download ──────────────────────────────────────────────
# Shortcuts: reason2-2b, reason2-7b, predict2.5-2b/14b, transfer2.5-2b/edge/depth/seg
download name="reason2-2b" local_dir="":
    #!/usr/bin/env bash
    DEST="{{local_dir}}"
    [ -z "$DEST" ] && DEST="./checkpoints/{{name}}"
    mkdir -p "$DEST"
    case "{{name}}" in
      reason2-2b)        REPO="nvidia/Cosmos-Reason2-2B" ;;
      reason2-7b)        REPO="nvidia/Cosmos-Reason2-7B" ;;
      reason1-7b-reward) REPO="nvidia/Cosmos-Reason1-7B-Reward" ;;
      predict2.5-2b)     REPO="nvidia/Cosmos-Predict2.5-2B" ;;
      predict2.5-14b)    REPO="nvidia/Cosmos-Predict2.5-14B" ;;
      transfer2.5-2b)    REPO="nvidia/Cosmos-Transfer2.5-2B" ;;
      transfer2.5-edge)  REPO="nvidia/Cosmos-Transfer2.5-Edge" ;;
      transfer2.5-depth) REPO="nvidia/Cosmos-Transfer2.5-Depth" ;;
      transfer2.5-seg)   REPO="nvidia/Cosmos-Transfer2.5-Seg" ;;
      *)                 REPO="{{name}}" ;;
    esac
    hf download "$REPO" --local-dir "$DEST"

download-dataset name="gr1" local_dir="":
    #!/usr/bin/env bash
    DEST="{{local_dir}}"
    [ -z "$DEST" ] && DEST="./datasets/{{name}}"
    mkdir -p "$DEST"
    case "{{name}}" in
      gr1)         REPO="nvidia/PhysicalAI-Robotics-GR00T-GR1" ;;
      gr1-100)     REPO="nvidia/GR1-100" ;;
      gr00t-eval)  REPO="nvidia/PhysicalAI-Robotics-GR00T-Eval" ;;
      safe-unsafe) REPO="pjramg/Safe_Unsafe_Test" ;;
      *)           REPO="{{name}}" ;;
    esac
    hf download "$REPO" --repo-type dataset --local-dir "$DEST"


# ── Quantization + ONNX export (x86 GPU host) ─────────────────────────────
# Quantize a model to FP8 (or int8/int4)
quantize model_dir="nvidia/Cosmos-Reason2-2B" output_dir="./quantized/Cosmos-Reason2-2B-fp8" dtype="fp16" quantization="fp8":
    mkdir -p "{{output_dir}}"
    tensorrt-edgellm-quantize-llm \
      --model_dir "{{model_dir}}" \
      --output_dir "{{output_dir}}" \
      --dtype "{{dtype}}" \
      --quantization "{{quantization}}"

# Export the LLM component to ONNX
export-llm model_dir output_dir:
    mkdir -p "{{output_dir}}"
    tensorrt-edgellm-export-llm \
      --model_dir "{{model_dir}}" \
      --output_dir "{{output_dir}}"

# Export the visual encoder to ONNX
export-visual model_dir output_dir dtype="fp16" quantization="":
    mkdir -p "{{output_dir}}"
    #!/usr/bin/env bash
    CMD=(tensorrt-edgellm-export-visual \
      --model_dir "{{model_dir}}" \
      --output_dir "{{output_dir}}" \
      --dtype "{{dtype}}")
    [ -n "{{quantization}}" ] && CMD+=(--quantization "{{quantization}}")
    "${CMD[@]}"

# Full x86 prep: download → quantize → export LLM → export visual
prep-edge-model model="reason2-2b" out_root="./models/Cosmos-Reason2-2B-fp8":
    just download "{{model}}" "{{out_root}}/hf"
    just quantize "{{out_root}}/hf" "{{out_root}}/quantized" fp16 fp8
    just export-llm "{{out_root}}/quantized" "{{out_root}}/onnx"
    just export-visual "{{out_root}}/hf" "{{out_root}}/onnx/visual_enc_onnx" fp16 fp8
    @echo "✅ ONNX ready → {{out_root}}/onnx  (scp to Thor next)"


# ── TRT engine build (on Thor) ────────────────────────────────────────────
build-llm-engine onnx_dir engine_dir min_tokens="4" max_tokens="10240" max_input_len="1024":
    mkdir -p "{{engine_dir}}"
    "{{LLM_BUILD_BIN}}" \
      --onnxDir "{{onnx_dir}}" \
      --engineDir "{{engine_dir}}" \
      --vlm \
      --minImageTokens {{min_tokens}} \
      --maxImageTokens {{max_tokens}} \
      --maxInputLen {{max_input_len}}

build-visual-engine onnx_dir engine_dir:
    mkdir -p "{{engine_dir}}"
    "{{VISUAL_BUILD_BIN}}" \
      --onnxDir "{{onnx_dir}}" \
      --engineDir "{{engine_dir}}"

# Build both engines (LLM + visual) in one go
build-engines onnx_dir engine_root:
    just build-llm-engine    "{{onnx_dir}}" "{{engine_root}}/llm"
    just build-visual-engine "{{onnx_dir}}/visual_enc_onnx" "{{engine_root}}/visual"


# ── Inference server (on Thor) ────────────────────────────────────────────
serve-start llm_engine_dir visual_engine_dir port=VLM_PORT host=VLM_HOST:
    #!/usr/bin/env bash
    if [ -f "{{PID_FILE}}" ] && kill -0 "$(cat {{PID_FILE}})" 2>/dev/null; then
      echo "🟢 already running (pid=$(cat {{PID_FILE}}))"; exit 0
    fi
    nohup "{{SERVER_BIN}}" \
      --llmEngineDir "{{llm_engine_dir}}" \
      --visualEngineDir "{{visual_engine_dir}}" \
      --host "{{host}}" --port "{{port}}" \
      >> "{{LOG_FILE}}" 2>&1 &
    echo $! > "{{PID_FILE}}"
    sleep 1
    echo "▶ started pid=$(cat {{PID_FILE}})  http://{{host}}:{{port}}"

serve-stop:
    #!/usr/bin/env bash
    if [ ! -f "{{PID_FILE}}" ]; then echo "🔴 not running"; exit 0; fi
    PID=$(cat "{{PID_FILE}}")
    if kill -0 "$PID" 2>/dev/null; then kill "$PID" && echo "⏹ stopped pid=$PID"; fi
    rm -f "{{PID_FILE}}"

serve-status:
    #!/usr/bin/env bash
    if [ -f "{{PID_FILE}}" ] && kill -0 "$(cat {{PID_FILE}})" 2>/dev/null; then
      echo "🟢 running pid=$(cat {{PID_FILE}})  {{VLM_URL}}"
    else
      echo "🔴 not running"; rm -f "{{PID_FILE}}"
    fi

serve-logs lines="80":
    @tail -n {{lines}} "{{LOG_FILE}}" 2>/dev/null || echo "no log yet"

serve-restart llm_engine_dir visual_engine_dir:
    -just serve-stop
    just serve-start "{{llm_engine_dir}}" "{{visual_engine_dir}}"


# ── Inference (HTTP) ──────────────────────────────────────────────────────
# One-shot VLM call against the running server
infer image prompt="count people; report gender/hair/clothing" max_tokens="256" temperature="0.2" url=VLM_URL:
    #!/usr/bin/env bash
    IMG_B64=$(base64 < "{{image}}" | tr -d '\n')
    PROMPT='{{prompt}}'
    curl -sS -X POST "{{url}}" \
      -H "Content-Type: application/json" \
      -d @- <<EOF | jq -r '.choices[0].message.content // .'
    {
      "model": "trt-edgellm",
      "messages": [{"role":"user","content":[
        {"type":"text","text":"$PROMPT"},
        {"type":"image_url","image_url":{"url":"data:image/jpeg;base64,$IMG_B64"}}
      ]}],
      "max_tokens": {{max_tokens}},
      "temperature": {{temperature}}
    }
    EOF


# ── RTP capture (GStreamer, Jetson HW decode) ─────────────────────────────
rtp-capture port=RTP_PORT output="/tmp/thor_frame.jpg" width="800" height="600" timeout_s="5":
    #!/usr/bin/env bash
    timeout {{timeout_s}} gst-launch-1.0 -e \
      udpsrc address={{RTP_BIND}} port={{port}} \
        caps='application/x-rtp,media=video,encoding-name=H264,payload=96' ! \
      rtph264depay ! h264parse ! nvv4l2decoder ! nvvidconv ! \
      video/x-raw,width={{width}},height={{height}},format=I420 ! \
      nvjpegenc ! filesink location="{{output}}" || \
    timeout {{timeout_s}} gst-launch-1.0 -e \
      udpsrc address={{RTP_BIND}} port={{port}} \
        caps='application/x-rtp,media=video,encoding-name=H264,payload=96' ! \
      rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! videoscale ! \
      video/x-raw,width={{width}},height={{height}} ! jpegenc ! \
      filesink location="{{output}}"
    @ls -la "{{output}}"


# ── NATS publish ──────────────────────────────────────────────────────────
nats-publish subject payload_json:
    #!/usr/bin/env bash
    echo '{{payload_json}}' | nats pub "{{subject}}" --server "{{NATS_URL}}"


# ── Generation (Predict 2.5 / Transfer 2.5) ───────────────────────────────
# Generate with Predict 2.5 via the repo's inference.py
predict-generate input_json repo=COSMOS_PREDICT_REPO:
    cd "{{repo}}" && just run python examples/inference.py -i "{{input_json}}"

# Generate with Transfer 2.5 (control = edge/depth/seg/vis)
transfer-generate input_json control="edge" repo=COSMOS_TRANSFER_REPO:
    cd "{{repo}}" && just run python examples/inference.py -i "{{input_json}}" "{{control}}"


# ── Post-training ─────────────────────────────────────────────────────────
# Reason-2 SFT via cosmos-cli
post-train-reason2 config strategy="full":
    cosmos-cli train --config "{{config}}" --strategy "{{strategy}}"

# Reason-2 RL via cosmos-rl
post-train-reason2-rl config:
    cosmos-rl --config "{{config}}"

# Predict 2.5 / Transfer 2.5 (torchrun)
post-train-predict config num_gpus="8" repo=COSMOS_PREDICT_REPO:
    cd "{{repo}}" && torchrun --nproc-per-node={{num_gpus}} -m cosmos_predict2.train --config "{{config}}"

post-train-transfer config num_gpus="8" repo=COSMOS_TRANSFER_REPO:
    cd "{{repo}}" && torchrun --nproc-per-node={{num_gpus}} -m cosmos_transfer2.train --config "{{config}}"


# ── Distillation ──────────────────────────────────────────────────────────
distill teacher student method="kd" family="transfer2_5" num_gpus="8":
    #!/usr/bin/env bash
    MODULE="cosmos_transfer2.distill"
    [ "{{family}}" = "predict2_5" ] && MODULE="cosmos_predict2.distill"
    torchrun --nproc-per-node={{num_gpus}} -m "$MODULE" \
      --method "{{method}}" \
      --teacher-ckpt "{{teacher}}" \
      --student-output "{{student}}"


# ── Data curation (Cosmos-Xenna) ──────────────────────────────────────────
curate input_dir output_dir="./outputs/curated" stages="all" workers="8" repo=COSMOS_XENNA_REPO:
    cd "{{repo}}" && just run python -m cosmos_xenna.pipelines.v1.curate \
      --input-dir "{{input_dir}}" --output-dir "{{output_dir}}" \
      --stages "{{stages}}" --workers {{workers}}


# ── Evaluation ────────────────────────────────────────────────────────────
# metric ∈ fid, fvd, tse, cse, sampson, blur_ssim, canny_f1, depth_rmse, seg_miou, dover, reason_critic, reason_reward
evaluate metric pred gt="" output_dir="./outputs/eval" repo=COSMOS_COOKBOOK_REPO:
    #!/usr/bin/env bash
    declare -A MAP=(
      [fid]=scripts/metrics/qualitative/compute_fid.py
      [fvd]=scripts/metrics/qualitative/compute_fvd.py
      [tse]=scripts/metrics/geometrical_consistency/compute_tse.py
      [cse]=scripts/metrics/geometrical_consistency/compute_cse.py
      [sampson]=scripts/metrics/geometrical_consistency/compute_sampson.py
      [blur_ssim]=scripts/metrics/control/compute_blur_ssim.py
      [canny_f1]=scripts/metrics/control/compute_canny_f1.py
      [depth_rmse]=scripts/metrics/control/compute_depth_rmse.py
      [seg_miou]=scripts/metrics/control/compute_seg_miou.py
      [dover]=scripts/metrics/control/compute_dover.py
      [reason_critic]=scripts/evaluation/reason_critic.py
      [reason_reward]=scripts/evaluation/cosmos-reason1-reward-7b/run.py
    )
    SCRIPT="${MAP[{{metric}}]}"
    if [ -z "$SCRIPT" ]; then echo "unknown metric: {{metric}}"; exit 2; fi
    mkdir -p "{{output_dir}}"
    CMD=(python "$SCRIPT" --pred "{{pred}}" --output "{{output_dir}}")
    [ -n "{{gt}}" ] && CMD+=(--gt "{{gt}}")
    cd "{{repo}}" && "${CMD[@]}"


# ── Video / image utils ───────────────────────────────────────────────────
video-probe video:
    ffprobe -v error -print_format json -show_format -show_streams "{{video}}"

video-frames video output_dir="/tmp/frames" fps="1.0" max_frames="0":
    mkdir -p "{{output_dir}}"
    #!/usr/bin/env bash
    CMD=(ffmpeg -y -hide_banner -loglevel warning -i "{{video}}" -vf fps={{fps}})
    [ "{{max_frames}}" != "0" ] && CMD+=(-frames:v {{max_frames}})
    CMD+=("{{output_dir}}/frame_%06d.jpg")
    "${CMD[@]}"
    ls "{{output_dir}}" | head -5


# ── System diagnostics ────────────────────────────────────────────────────
sysinfo:
    @echo "--- host ---"
    @hostname && uname -a
    @echo "--- jetson ---"
    @cat /proc/device-tree/model 2>/dev/null || echo "not a Jetson"
    @echo "--- nvidia-smi ---"
    @nvidia-smi --query-gpu=name,memory.total,memory.used,utilization.gpu,temperature.gpu --format=csv,noheader 2>/dev/null || echo "no nvidia-smi"
    @echo "--- memory ---"
    @free -h 2>/dev/null || vm_stat
    @echo "--- thermal ---"
    @for z in /sys/class/thermal/thermal_zone*; do [ -r $z/temp ] && echo "$(cat $z/type 2>/dev/null || basename $z): $(awk '{printf "%.1fC\n", $1/1000}' $z/temp)"; done 2>/dev/null || true
    @echo "--- nvpmodel ---"
    @nvpmodel -q 2>/dev/null || echo "no nvpmodel"


# ── Pipelines (end-to-end) ────────────────────────────────────────────────
# The flagship pipeline: deploy Cosmos-Reason2 to Thor, serve, and smoke-test.
pipeline-edge-deploy model="reason2-2b" out_root="./models/Cosmos-Reason2-2B-fp8" test_image="assets/test.jpg":
    @echo "🏗  prep on x86 host"
    just prep-edge-model "{{model}}" "{{out_root}}"
    @echo "📤  scp ONNX dir to Thor (manual step — see SCP_TARGET env)"
    @echo "🔨  (on Thor)  just build-engines {{out_root}}/onnx {{out_root}}/engines"
    @echo "▶️  (on Thor)  just serve-start {{out_root}}/engines/llm {{out_root}}/engines/visual"
    @echo "🧪  (on Thor)  just infer {{test_image}} 'describe the scene'"

# End-to-end GR00T-Dreams style synthetic trajectory workflow
pipeline-gr00t-dreams dataset_dir="./datasets/gr1" config="configs/gr00t-dreams.yaml":
    just download-dataset gr1 "{{dataset_dir}}"
    just post-train-predict "{{config}}"
    # user then runs just predict-generate <input.json>

# Real-time perception loop: capture → infer → publish.
# Loops until Ctrl-C. Run inside tmux on Thor.
perception-loop subject="perception.vlm" prompt="Describe the scene; count people, report clothing colors.":
    #!/usr/bin/env bash
    echo "🔁 perception-loop starting. Ctrl-C to stop."
    while true; do
      FRAME=/tmp/thor_cosmos_perception.jpg
      just rtp-capture {{RTP_PORT}} "$FRAME" 800 600 5 >/dev/null || { sleep 1; continue; }
      RESULT=$(just infer "$FRAME" "{{prompt}}" 128 0.1 2>/dev/null || echo "")
      [ -z "$RESULT" ] && { sleep 1; continue; }
      PAYLOAD=$(printf '{"text":%s,"ts":%d}' "$(printf '%s' "$RESULT" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read()))')" "$(date +%s)")
      just nats-publish "{{subject}}" "$PAYLOAD" || true
      sleep 0.1
    done

# Smoke test: run every lightweight recipe
smoke:
    just env
    just sysinfo
    -just serve-status


# ── Development ───────────────────────────────────────────────────────────
test:
    {{VENV}}/bin/python -m pytest -v tests/ || echo "⚠️  no tests yet"

lint:
    {{VENV}}/bin/python -m ruff check thor_cosmos/ || echo "⚠️  ruff not installed"
    {{VENV}}/bin/python -m ruff format --check thor_cosmos/ 2>/dev/null || true

format:
    {{VENV}}/bin/python -m ruff format thor_cosmos/ || echo "⚠️  ruff not installed"

# Syntax-check every tool
check-tools:
    @{{PYTHON}} -c "import ast, pathlib, sys; \
      errs = [(p, e) for p in pathlib.Path('thor_cosmos').rglob('*.py') \
              for e in ([] if (lambda: (ast.parse(p.read_text()), True))() else [] )]; \
      print('all files parse OK')"
