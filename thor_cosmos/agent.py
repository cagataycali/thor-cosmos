"""
thor-cosmos — minimal Strands agent with a while True: agent(input()) loop.

Full Cosmos ecosystem coverage:
  Edge (Thor)   : cosmos_inference, cosmos_serve, cosmos_build_engine,
                  rtp_capture_frame, nats_publish, system_info
  x86 GPU host  : cosmos_quantize, cosmos_export_onnx, cosmos_model_download,
                  cosmos_reason_hf
  Generation    : cosmos_predict_generate (Predict2.5),
                  cosmos_transfer_generate (Transfer2.5 edge/depth/seg/vis)
  Training      : cosmos_post_train (reason2/predict2.5/transfer2.5),
                  cosmos_distill (KD / DMD2)
  Data + eval   : cosmos_curate (Xenna), cosmos_evaluate (FID/FVD/TSE/CSE/...)
  Utilities     : video_probe, video_extract_frames, image_read
"""
from __future__ import annotations

import logging
import os
import signal
import sys

from strands import Agent
from strands.models import BedrockModel

from thor_cosmos.tools import (
    # Edge inference (Thor)
    cosmos_inference,
    cosmos_serve,
    cosmos_build_engine,
    rtp_capture_frame,
    nats_publish,
    system_info,
    # x86 model prep
    cosmos_quantize,
    cosmos_export_onnx,
    cosmos_model_download,
    cosmos_reason_hf,
    # Generation
    cosmos_predict_generate,
    cosmos_transfer_generate,
    # Training
    cosmos_post_train,
    cosmos_distill,
    # Data + eval
    cosmos_curate,
    cosmos_evaluate,
    # Utilities
    video_probe,
    video_extract_frames,
    image_read,
)

logging.basicConfig(
    level=os.getenv("THOR_COSMOS_LOG_LEVEL", "INFO"),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
log = logging.getLogger("thor-cosmos")


SYSTEM_PROMPT = """You are **thor-cosmos**, an agent that orchestrates the
NVIDIA Cosmos ecosystem for Physical AI / Robotics.

You run on either:
  • a Jetson AGX Thor edge device (primary — Robot/VLM perception)
  • an x86 GPU host (model prep, generation, training, distillation)

Your toolkit spans 4 Cosmos families and their full lifecycle:

  **Cosmos-Reason2** (VLM, reasoning)
    - cosmos_inference          → TRT-EdgeLLM server on Thor (real-time)
    - cosmos_reason_hf          → HuggingFace inference (full precision, x86)
    - cosmos_quantize           → FP8 quantization (x86)
    - cosmos_export_onnx        → LLM/visual ONNX export (x86)
    - cosmos_build_engine       → TRT engine build (Thor)
    - cosmos_serve              → start/stop local TRT server (Thor)

  **Cosmos-Predict2.5** (world model / video generation)
    - cosmos_predict_generate   → text2world, video2world, action-conditioned, multiview
    - cosmos_distill            → step distillation (KD / DMD2)

  **Cosmos-Transfer2.5** (ControlNet — video style/structure transfer)
    - cosmos_transfer_generate  → edge / depth / seg / vis / multi-control
    - cosmos_distill            → step distillation (KD / DMD2)

  **Training + data**
    - cosmos_post_train         → reason2 (SFT/RL), predict2.5, transfer2.5
    - cosmos_curate             → Cosmos-Xenna curation pipeline (7 stages)
    - cosmos_evaluate           → FID/FVD/TSE/CSE/canny_f1/depth_rmse/seg_miou/reason_critic

  **Edge / I/O**
    - rtp_capture_frame         → GStreamer JPEG from RTP stream (HW decode)
    - nats_publish              → perception.vlm events
    - image_read / video_probe / video_extract_frames
    - system_info               → Jetson thermals, GPU, memory
    - cosmos_model_download     → HF downloads (known Cosmos models/datasets)

## Rules
1. Be terse. No preamble. Execute tools directly.
2. On Thor → prefer edge tools (inference/serve/build_engine/capture).
3. On x86 host → prefer quantize/export/generate/post_train/curate/evaluate.
4. Batch independent tool calls in ONE message (parallel).
5. For the intbot-style edge pipeline (deploy VLM to Thor), chain:
     download → quantize → export_onnx(llm) + export_onnx(visual) →
     scp to Thor → build_engine(llm) + build_engine(visual) → serve → inference.
6. For synthetic trajectory generation (GR00T-Dreams style):
     post_train(predict2_5) → predict_generate → evaluate(reason_critic).
7. For style-guided video generation:
     transfer_generate(control=edge, style_image=...) → evaluate(canny_f1).
8. If a command fails, read the actual error and fix it. Do not guess.

Keep state small. Stream insights iteration-by-iteration.
"""


def build_agent() -> Agent:
    provider = os.getenv("THOR_COSMOS_PROVIDER", "bedrock")
    model_id = os.getenv(
        "THOR_COSMOS_MODEL_ID",
        "global.anthropic.claude-opus-4-6-v1",
    )

    if provider == "bedrock":
        model = BedrockModel(
            model_id=model_id,
            region_name=os.getenv("AWS_REGION", "us-west-2"),
        )
    elif provider == "openai":
        from strands.models.openai import OpenAIModel
        model = OpenAIModel(model_id=os.getenv("THOR_COSMOS_MODEL_ID", "gpt-4o-mini"))
    elif provider == "ollama":
        from strands.models.ollama import OllamaModel
        model = OllamaModel(
            host=os.getenv("OLLAMA_HOST", "http://localhost:11434"),
            model_id=os.getenv("THOR_COSMOS_MODEL_ID", "qwen2.5:7b"),
        )
    else:
        raise SystemExit(f"unknown THOR_COSMOS_PROVIDER={provider}")

    return Agent(
        model=model,
        system_prompt=SYSTEM_PROMPT,
        tools=[
            # Edge inference (Thor)
            cosmos_inference,
            cosmos_serve,
            cosmos_build_engine,
            rtp_capture_frame,
            nats_publish,
            system_info,
            # x86 model prep
            cosmos_quantize,
            cosmos_export_onnx,
            cosmos_model_download,
            cosmos_reason_hf,
            # Generation
            cosmos_predict_generate,
            cosmos_transfer_generate,
            # Training
            cosmos_post_train,
            cosmos_distill,
            # Data + eval
            cosmos_curate,
            cosmos_evaluate,
            # Utilities
            video_probe,
            video_extract_frames,
            image_read,
        ],
    )


def _handle_sigterm(signum, frame):
    log.info("received signal %s — shutting down cleanly", signum)
    sys.exit(0)


def main() -> None:
    signal.signal(signal.SIGTERM, _handle_sigterm)
    signal.signal(signal.SIGINT, _handle_sigterm)

    agent = build_agent()

    model_id = getattr(agent.model, "config", {}).get("model_id", "?") if hasattr(agent.model, "config") else "?"
    print("🤖🌌 thor-cosmos agent — ready")
    print(f"    model = {model_id}")
    print(f"    tools = {len(agent.tool_names) if hasattr(agent, 'tool_names') else '?'}")
    print("    type 'exit' or Ctrl-C to quit\n")

    while True:
        try:
            prompt = input("🌌 ▸ ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if not prompt:
            continue
        if prompt.lower() in {"exit", "quit", ":q"}:
            break

        try:
            agent(prompt)
        except Exception as e:  # noqa: BLE001
            log.exception("agent error: %s", e)


if __name__ == "__main__":
    main()
