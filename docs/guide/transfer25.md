# Cosmos-Transfer 2.5 (ControlNet)

Transfer 2.5 does ControlNet-style video generation: you provide a *control signal* (edge, depth, seg, vis) and a text prompt, it synthesizes a matching video.

## Control modes

| Mode | Signal | Use case |
|---|---|---|
| `edge` | Canny edges | Structure-preserving restyle |
| `depth` | Depth map | 3D-aware generation |
| `seg` | Semantic segmentation | Scene composition |
| `vis` | Visibility / masks | Inpainting, editing |
| `multi` | Weighted combination | Multi-signal control |

## Agent tool

```python
cosmos_transfer_generate(
    prompt="Tokyo street at night, neon lights, rainy",
    control="edge",
    output_dir="./outputs/transfer2_5",
    control_video="./source_edges.mp4",  # optional pre-computed
    style_image="./reference.png",       # optional image-prompt
    guidance_scale=3.0,
    num_steps=35,
    seed=42,
)
```

For `control="multi"` provide `control_weights`:

```python
cosmos_transfer_generate(
    prompt="...",
    control="multi",
    control_weights={"edge": 0.7, "depth": 0.3},
    ...
)
```

## CLI

```bash
just transfer-generate inputs/my_spec.json edge
just transfer-generate inputs/my_spec.json depth
just transfer-generate inputs/multi.json multi
```

The `control` positional arg picks the example script in the upstream repo; for `multi`, the JSON's hint keys choose the combination.

## Image-prompt workflow

Use a style reference image to guide appearance while control video dictates structure:

```python
cosmos_transfer_generate(
    prompt="cyberpunk alleyway",
    control="edge",
    control_video="./raw.mp4",
    style_image="./cyberpunk_ref.jpg",
)
```

See [image-prompt transfer recipe](https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/inference/transfer2_5/inference-image-prompt/inference.html).

## Evaluation

Match metrics to control type:

| Control | Metric |
|---|---|
| `edge` | `canny_f1` |
| `depth` | `depth_rmse` |
| `seg` | `seg_miou` |
| any | `blur_ssim`, `dover`, `fid`, `fvd` |

```python
cosmos_evaluate(metric="canny_f1",
                pred_path="./outputs/transfer2_5",
                gt_path="./ground-truth")
```

## Distillation

Same `cosmos_distill` tool, `model_family="transfer2_5"`:

```python
cosmos_distill(
    teacher_checkpoint="./ckpts/transfer2.5-teacher",
    student_output="./ckpts/transfer2.5-4step",
    method="dmd2",
    model_family="transfer2_5",
)
```
