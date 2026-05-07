# Evaluation Metrics

Twelve metrics, organized by what they measure.

## Agent tool

```python
cosmos_evaluate(
    metric="fvd",
    pred_path="./outputs/predict2_5",
    gt_path="./ground-truth",
    output_dir="./outputs/eval",
)
```

## Metric catalogue

### Video quality (Predict 2.5)
| Metric | What | Script |
|---|---|---|
| `fid` | Frechet Inception Distance (image-level) | `scripts/metrics/qualitative/compute_fid.py` |
| `fvd` | Frechet Video Distance (video-level) | `scripts/metrics/qualitative/compute_fvd.py` |
| `dover` | Disentangled video quality | `scripts/metrics/control/compute_dover.py` |

### Geometrical consistency (Predict 2.5)
| Metric | What |
|---|---|
| `tse` | Triangulation / Scene Evaluation — stereo consistency |
| `cse` | Camera / Scene Evaluation — pose-aware |
| `sampson` | Sampson distance — epipolar-geometry fit |

### Control fidelity (Transfer 2.5)
| Metric | Matches |
|---|---|
| `canny_f1` | Edge-control output vs. Canny of GT |
| `depth_rmse` | Depth-control output vs. GT depth |
| `seg_miou` | Seg-control output vs. GT segmentation |
| `blur_ssim` | Visibility / blur preservation |

### VLM reasoning
| Metric | What |
|---|---|
| `reason_critic` | Cosmos-Reason2 judges output quality |
| `reason_reward` | Cosmos-Reason1-7B-Reward scalar |

## CLI

```bash
just evaluate fvd ./outputs/predict ./gt
just evaluate canny_f1 ./outputs/transfer ./gt
just evaluate reason_critic ./outputs/predict ""   # no GT needed
```

## Pick the right metric

| You're evaluating | Use |
|---|---|
| Unconditional Predict 2.5 generation | `fid`, `fvd` |
| Action-conditioned Predict 2.5 | `fvd`, `tse`, `reason_critic` |
| Transfer 2.5 with `edge` control | `canny_f1`, `fid` |
| Transfer 2.5 with `depth` control | `depth_rmse`, `fid` |
| Transfer 2.5 with `seg` control | `seg_miou`, `fid` |
| VLM perception quality | `reason_critic`, `reason_reward` |

## Output format

Each metric writes a JSON report under `output_dir`:

```json
{
  "metric": "fvd",
  "score": 118.4,
  "n_samples": 32,
  "pred_path": "./outputs/predict",
  "gt_path": "./ground-truth",
  "timestamp": "2026-05-07T12:34:56Z"
}
```

## References

- [Evaluation overview](https://nvidia-cosmos.github.io/cosmos-cookbook/core_concepts/evaluation/overview.html)
