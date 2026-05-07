# Cosmos-Xenna (Data Curation)

Xenna is NVIDIA's 7-stage video data curation pipeline — the same one used to prepare Cosmos training corpora.

## Stages

1. **split** — shot detection & clipping
2. **transcode** — normalize resolution/fps/codec
3. **crop** — detect and remove borders/letterboxing
4. **filter** — drop low-quality / duplicate / unsafe clips
5. **caption** — auto-label with VLM captions
6. **dedup** — embedding-based near-dupe removal
7. **shard** — pack into WebDataset/TAR shards

## Agent tool

```python
cosmos_curate(
    input_dir="./raw_videos",
    output_dir="./outputs/curated",
    stages="all",                     # or "split,transcode,filter"
    num_workers=8,
)
```

## CLI

```bash
just curate ./raw_videos ./outputs/curated all 8
just curate ./raw_videos ./outputs/curated "split,caption" 4
```

## Typical pipelines

### Full pipeline
```bash
just curate ./raw ./curated all 16
```

### Captioning only (already cleaned)
```bash
just curate ./cleaned ./captioned caption 8
```

### Test run (subset of stages)
```bash
just curate ./test_videos ./out "split,transcode" 4
```

## Ray cluster

Xenna uses Ray for distributed work. The `num_workers` arg controls parallelism per node. For multi-node, configure Ray in your Cosmos-Xenna clone (see `COSMOS_XENNA_REPO`).

## Output layout

```
outputs/curated/
├── shards/
│   ├── train-000000.tar
│   ├── train-000001.tar
│   └── ...
├── captions/
│   └── captions.parquet
└── stats.json
```

## References

- [Data curation overview](https://nvidia-cosmos.github.io/cosmos-cookbook/core_concepts/data_curation/overview.html)
- [Cosmos-Xenna repo](https://github.com/nvidia-cosmos/cosmos-xenna)
