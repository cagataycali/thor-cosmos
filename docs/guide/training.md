# Training & Distillation

thor-cosmos wraps four post-training entry points plus step distillation.

## Post-training tool

```python
cosmos_post_train(
    config_path="configs/my-sft.yaml",
    model_family="reason2",            # reason2 | predict2_5 | transfer2_5
    strategy="full",                   # full | lora | rl
    num_gpus=8,
    dry_run=False,
)
```

## Per-family dispatch

| Family | Strategy | Recipe | Backend |
|---|---|---|---|
| `reason2` | `full` or `lora` | `post-train-reason2` | `cosmos-cli train` |
| `reason2` | `rl` | `post-train-reason2-rl` | `cosmos-rl` |
| `predict2_5` | n/a | `post-train-predict` | `torchrun -m cosmos_predict2.train` |
| `transfer2_5` | n/a | `post-train-transfer` | `torchrun -m cosmos_transfer2.train` |

## CLI examples

### Reason-2 SFT (LoRA)
```bash
just post-train-reason2 configs/reason2-sft.yaml lora
```

### Reason-2 RLHF / DPO
```bash
just post-train-reason2-rl configs/reason2-dpo.yaml
```

### Predict 2.5 fine-tune
```bash
just post-train-predict configs/gr00t-dreams.yaml 8
```

### Transfer 2.5 fine-tune
```bash
just post-train-transfer configs/indoor-restyle.yaml 8
```

## Distillation

Step distillation (Teacher → Student with fewer denoising steps).

```python
cosmos_distill(
    teacher_checkpoint="./ckpts/transfer-teacher",
    student_output="./ckpts/transfer-4step",
    method="dmd2",                     # kd | dmd2
    model_family="transfer2_5",        # transfer2_5 | predict2_5
    num_gpus=8,
)
```

### `kd` vs `dmd2`

- **`kd`** (Knowledge Distillation): Student mimics Teacher's outputs. Stable, slower convergence.
- **`dmd2`** (Distribution Matching Distillation v2): Matches output distributions. Faster, needs more tuning.

## Config discovery

Training configs usually live under `configs/` in the relevant upstream repo. The cookbook recipes publish ready-to-use configs for GR00T-Dreams, indoor restyle, etc.

## Monitoring

- **stdout**: the tool streams last 8 KB of stdout/stderr into the Strands result
- **TensorBoard**: most upstream configs write to `./logs/tb/`
- **W&B**: set `WANDB_PROJECT` in env; upstream configs pick it up
