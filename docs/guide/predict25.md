# Cosmos-Predict 2.5 (World Model)

Predict 2.5 is NVIDIA's video world model. It generates future frames from text, image, or action inputs.

## Variants

| Variant | Input | Output | Use case |
|---|---|---|---|
| `text2world` | Text prompt | Video | Scene synthesis from scratch |
| `video2world` | Video + prompt | Video continuation | Forecasting |
| `action_conditioned` | Video + action sequence | Video | Trajectory simulation, robotics |
| `multiview` | Multi-cam rig | Multi-view video | 3D-consistent generation |

## Agent tool

```python
cosmos_predict_generate(
    prompt="a robot arm placing a cup on a table",
    output_dir="./outputs/predict2_5",
    input_video="./seed.mp4",         # for video2world
    num_frames=121,
    height=720,
    width=1280,
    fps=24,
    guidance_scale=7.0,
    num_steps=35,
    seed=0,
    model_variant="video2world",
    checkpoint="./ckpts/my-finetune",  # optional
)
```

The tool writes parameters to a temp JSON and invokes:

```bash
just predict-generate /tmp/predict_XXX.json
# → cd $COSMOS_PREDICT_REPO
# → just run python examples/inference.py -i /tmp/predict_XXX.json
```

## CLI

```bash
# Using the repo's own examples
just predict-generate inputs/my_video2world.json
```

## Typical workflow

```bash
just download predict2.5-2b        # grab the base checkpoint
just post-train-predict configs/gr00t.yaml 8  # optional fine-tune
just predict-generate inputs/scene.json
just evaluate fvd ./outputs/predict2_5 ./ground-truth
```

## Distillation (fewer steps)

```python
cosmos_distill(
    teacher_checkpoint="./ckpts/predict2.5-teacher",
    student_output="./ckpts/predict2.5-4step",
    method="dmd2",                    # "kd" or "dmd2"
    model_family="predict2_5",
    num_gpus=8,
)
```

## References

- [Cosmos Cookbook — GR00T-Dreams](https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/end2end/gr00t-dreams/post-training.html)
- [Cosmos-Predict2.5 repo](https://github.com/nvidia-cosmos/cosmos-predict2.5)
