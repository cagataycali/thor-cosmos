# GR00T-Dreams · Synthetic Trajectory Generation

Generate synthetic robot training data by fine-tuning **Cosmos-Predict 2.5** on the GR00T GR1 dataset.

Adapted from [cookbook/end2end/gr00t-dreams](https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/end2end/gr00t-dreams/post-training.html).

## The idea

1. Take the **GR1 humanoid robot dataset** (VR teleop trajectories)
2. Fine-tune **Predict 2.5** on it → model learns GR1 dynamics
3. Generate **synthetic video trajectories** from new text prompts or action sequences
4. Use generated videos as augmentation for downstream VLA training

## Step 1 — Download

```bash
just download-dataset gr1
# ./datasets/gr1/  (tens of GB)
just download predict2.5-2b
# ./checkpoints/predict2.5-2b/
```

## Step 2 — Fine-tune

Grab the reference config from the cookbook (or write your own):

```bash
# Example config path inside $COSMOS_COOKBOOK_REPO:
CONFIG=$COSMOS_COOKBOOK_REPO/recipes/end2end/gr00t-dreams/config.yaml
```

Run:

```bash
just post-train-predict "$CONFIG" 8
# torchrun --nproc-per-node=8 -m cosmos_predict2.train --config $CONFIG
```

Outputs a fine-tuned checkpoint under `./checkpoints/gr00t-dreams/`.

## Step 3 — Generate

Make a `video2world` input JSON:

```json
{
  "prompt": "The robot arm picks up the red block and places it in the box",
  "input_video": "./datasets/gr1/task_001/first_frame.mp4",
  "num_frames": 121,
  "fps": 24,
  "guidance_scale": 7.0,
  "num_steps": 35,
  "output_dir": "./outputs/predict2_5"
}
```

Then:

```bash
just predict-generate inputs/video2world.json
```

Or via the agent:

```python
cosmos_predict_generate(
    prompt="The robot arm picks up the red block",
    input_video="./datasets/gr1/task_001/first_frame.mp4",
    checkpoint="./checkpoints/gr00t-dreams",
    model_variant="video2world",
    num_frames=121,
)
```

## Step 4 — Evaluate

```bash
just evaluate fvd ./outputs/predict2_5 ./datasets/gr1/eval
just evaluate reason_critic ./outputs/predict2_5 ""
```

## Pipeline recipe

Everything above is wrapped:

```bash
just pipeline-gr00t-dreams ./datasets/gr1 configs/gr00t-dreams.yaml
# → download-dataset gr1
# → post-train-predict configs/gr00t-dreams.yaml
# (user then runs predict-generate with their input JSON)
```

## Tips

- Use **8+ GPUs** for practical fine-tuning (L40S / H100)
- Start with **`num_steps=10`** during iteration; bump to 35 for final outputs
- **Seed sweep** (5-10 seeds per prompt) to pick best samples
- Evaluate with `reason_critic` to auto-filter low-quality generations
