# x86 Model Prep

Jetson Thor can't do FP8 quantization or ONNX export on its own — those steps live on an **x86 GPU host** (A100/H100). thor-cosmos ships one recipe that chains the four steps.

## One-liner

```bash
just prep-edge-model reason2-2b ./models/R2-fp8
```

Expands to:

```bash
just download reason2-2b           ./models/R2-fp8/hf
just quantize ./models/R2-fp8/hf   ./models/R2-fp8/quantized fp16 fp8
just export-llm ./models/R2-fp8/quantized ./models/R2-fp8/onnx
just export-visual ./models/R2-fp8/hf      ./models/R2-fp8/onnx/visual_enc_onnx fp16 fp8
# ✅ ONNX ready → ./models/R2-fp8/onnx  (scp to Thor next)
```

## Shortcuts: model names

| Name | HF repo |
|---|---|
| `reason2-2b` | `nvidia/Cosmos-Reason2-2B` |
| `reason2-7b` | `nvidia/Cosmos-Reason2-7B` |
| `predict2.5-2b` | `nvidia/Cosmos-Predict2.5-2B` |
| `predict2.5-14b` | `nvidia/Cosmos-Predict2.5-14B` |
| `transfer2.5-2b` | `nvidia/Cosmos-Transfer2.5-2B` |
| `transfer2.5-edge` | `nvidia/Cosmos-Transfer2.5-Edge` |
| `transfer2.5-depth` | `nvidia/Cosmos-Transfer2.5-Depth` |
| `transfer2.5-seg` | `nvidia/Cosmos-Transfer2.5-Seg` |

Any other name is passed through as-is to `hf download`.

## Shortcuts: datasets

| Name | HF repo |
|---|---|
| `gr1` | `nvidia/PhysicalAI-Robotics-GR00T-GR1` |
| `gr1-100` | `nvidia/GR1-100` |
| `gr00t-eval` | `nvidia/PhysicalAI-Robotics-GR00T-Eval` |
| `safe-unsafe` | `pjramg/Safe_Unsafe_Test` |

```bash
just download-dataset gr1 ./datasets/gr1
```

## Quantization precision

```bash
just quantize <model_dir> <output_dir> <dtype> <quantization>
```

| `dtype` | `quantization` | use case |
|---|---|---|
| `fp16` | `fp8` | **default for Thor** — 2x smaller, negligible quality loss |
| `bf16` | `fp8` | alternative base dtype |
| `fp16` | `int8` | older GPUs (no FP8 HW) |
| `fp16` | `int4` | aggressive compression, notable quality drop |

## ONNX export

```bash
just export-llm    <model_dir> <output_dir>
just export-visual <model_dir> <output_dir> <dtype> <quantization>
```

LLM export takes the quantized weights. Visual export takes the original HF weights — the visual encoder uses its own dtype/quant settings.

## Ship to Thor

```bash
scp -r ./models/R2-fp8/onnx cagatay@thor.local:~/R2-fp8-onnx
```

Then on Thor:

```bash
just build-engines ~/R2-fp8-onnx ~/R2-fp8-engines
```

→ [Thor deployment](thor-deploy.md)
