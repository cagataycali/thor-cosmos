# API Reference

All 19 Strands tools + 42 `just` recipes.

## Edge inference (Thor)

### `cosmos_inference`
Real-time VLM call against the TRT-EdgeLLM HTTP server.

| Arg | Type | Default | Notes |
|---|---|---|---|
| `prompt` | str | required | User instruction |
| `image_path` | str | "" | Mutually exclusive with `image_b64` |
| `image_b64` | str | "" | Base64 image alternative |
| `server_url` | str | `$COSMOS_VLM_URL` | Override endpoint |
| `max_tokens` | int | 256 | Keep low for latency |
| `temperature` | float | 0.2 | 0.0-0.2 for perception |
| `system_prompt` | str | "" | Optional system message |
| `return_image` | bool | False | Embed input image in response |

→ Recipe: `just infer <image> <prompt> [max_tokens] [temperature] [url]`

### `cosmos_serve`
Manage the TRT-EdgeLLM server lifecycle.

| Arg | Values |
|---|---|
| `action` | `start` / `stop` / `restart` / `status` / `logs` |
| `llm_engine_dir`, `visual_engine_dir` | required for start/restart |
| `port`, `host` | bind address |
| `lines` | log lines (status=logs) |

→ Recipes: `serve-start` / `serve-stop` / `serve-restart` / `serve-status` / `serve-logs`

### `cosmos_build_engine`
Build a TensorRT engine from ONNX on Thor.

| Arg | Default |
|---|---|
| `which_part` | `"llm"` or `"visual"` |
| `min_image_tokens` | 4 |
| `max_image_tokens` | 10240 |
| `max_input_len` | 1024 |

→ Recipes: `build-llm-engine`, `build-visual-engine`, `build-engines` (both)

### `rtp_capture_frame`
Capture one JPEG from RTP/H.264 (GStreamer, HW-accel).

| Arg | Default |
|---|---|
| `bind_ip` | `"0.0.0.0"` |
| `port` | 5600 |
| `width` | 800 |
| `height` | 600 |
| `timeout_s` | 5 |
| `return_image` | True (embeds bytes) |

→ Recipe: `just rtp-capture <port> <output> <w> <h> <timeout>`

### `nats_publish`
Publish a JSON payload to a NATS subject.

| Arg | Default |
|---|---|
| `subject` | required |
| `payload` | dict |
| `servers` | `$NATS_URL` |

→ Recipe: `just nats-publish <subject> <payload_json>`

### `system_info`
Host / Jetson / GPU summary.

→ Recipe: `just sysinfo`

---

## x86 model prep

### `cosmos_quantize`
FP8 / INT8 / INT4 quantization.

| Arg | Default |
|---|---|
| `model_dir` | `"nvidia/Cosmos-Reason2-2B"` |
| `output_dir` | `"./quantized/R2-fp8"` |
| `dtype` | `"fp16"` |
| `quantization` | `"fp8"` |

→ Recipe: `just quantize <model_dir> <output_dir> <dtype> <quantization>`

### `cosmos_export_onnx`
Export LLM or visual encoder to ONNX.

| Arg | Notes |
|---|---|
| `which_part` | `"llm"` or `"visual"` |
| `dtype`, `quantization` | visual only |

→ Recipes: `export-llm`, `export-visual`

### `cosmos_model_download`
HF download with known shortcuts.

| Arg | Default |
|---|---|
| `name` | required (shortcut or HF repo) |
| `local_dir` | `""` (default `./checkpoints/<name>`) |
| `kind` | `"model"` or `"dataset"` |

→ Recipes: `download`, `download-dataset`

### `cosmos_reason_hf`
HF Transformers inference (full-precision reference).

| Arg | Default |
|---|---|
| `image_path` | "" (or `video_path`) |
| `model_id` | `"nvidia/Cosmos-Reason2-2B"` |
| `max_new_tokens` | 256 |
| `temperature` | 0.2 |
| `device` | `"auto"` |

→ No recipe (direct Transformers call).

---

## Generation

### `cosmos_predict_generate`
World model video generation.

| Arg | Default |
|---|---|
| `prompt` | required |
| `model_variant` | `"video2world"` (also `text2world`, `action_conditioned`, `multiview`) |
| `num_frames`, `height`, `width`, `fps` | 121, 720, 1280, 24 |
| `guidance_scale` | 7.0 |
| `num_steps` | 35 |
| `seed` | 0 |
| `checkpoint` | "" (override) |
| `repo_dir` | "" (override `$COSMOS_PREDICT_REPO`) |

→ Recipe: `just predict-generate <input_json>`

### `cosmos_transfer_generate`
ControlNet-style video transfer.

| Arg | Default |
|---|---|
| `prompt` | required |
| `control` | `"edge"` (also `depth`, `seg`, `vis`, `multi`) |
| `control_video` | "" (optional) |
| `style_image` | "" (optional) |
| `control_weights` | dict (required for `control="multi"`) |
| `guidance_scale`, `num_steps`, `seed` | 3.0, 35, 0 |

→ Recipe: `just transfer-generate <input_json> <control>`

---

## Training

### `cosmos_post_train`
Post-train Reason2 / Predict2.5 / Transfer2.5.

| Arg | Values |
|---|---|
| `config_path` | required YAML |
| `model_family` | `reason2` / `predict2_5` / `transfer2_5` |
| `strategy` | `full` / `lora` / `rl` (reason2 only for `rl`) |
| `num_gpus` | 1 (predict/transfer) |
| `dry_run` | False |

→ Recipes: `post-train-reason2`, `post-train-reason2-rl`, `post-train-predict`, `post-train-transfer`

### `cosmos_distill`
Step distillation (KD / DMD2).

| Arg | Values |
|---|---|
| `teacher_checkpoint` | required |
| `student_output` | required |
| `method` | `"kd"` or `"dmd2"` |
| `model_family` | `"transfer2_5"` or `"predict2_5"` |
| `num_gpus` | 8 |

→ Recipe: `just distill <teacher> <student> <method> <family>`

---

## Data + Eval

### `cosmos_curate`
Cosmos-Xenna curation pipeline.

| Arg | Default |
|---|---|
| `input_dir` | required |
| `output_dir` | `"./outputs/curated"` |
| `stages` | `"all"` or comma-separated |
| `num_workers` | 8 |

→ Recipe: `just curate <input> <output> <stages> <workers>`

### `cosmos_evaluate`
12 metrics.

| Arg | Valid metrics |
|---|---|
| `metric` | `fid fvd tse cse sampson blur_ssim canny_f1 depth_rmse seg_miou dover reason_critic reason_reward` |
| `pred_path` | required |
| `gt_path` | required for most |
| `output_dir` | `"./outputs/eval"` |

→ Recipe: `just evaluate <metric> <pred> <gt>`

---

## Utilities

### `image_read`
Load an image and embed it in the response (Converse API compatible).

### `video_probe` / `video_extract_frames`
`ffprobe` JSON / extract frames at specified FPS.

→ Recipes: `video-probe`, `video-frames`

---

## Meta-recipes (pipelines)

| Recipe | Chain |
|---|---|
| `prep-edge-model` | download → quantize → export-llm → export-visual |
| `pipeline-edge-deploy` | prep-edge-model + Thor hand-off hints |
| `pipeline-gr00t-dreams` | download-dataset + post-train-predict |
| `perception-loop` | rtp-capture + infer + nats-publish (∞ loop) |
| `deploy-thor` | rsync + remote `just install` |
| `smoke` | env + sysinfo + serve-status |

## Env vars (quick reference)

See [Installation → Configure .env](getting-started/installation.md#configure-env).
