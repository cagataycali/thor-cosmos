# Real-Time Perception Loop

Continuous `RTP capture → VLM infer → NATS publish` loop, intended to run on Thor in a `tmux` session.

## The loop

```bash
just perception-loop perception.vlm \
  "Describe the scene; count people; report clothing colors."
```

Under the hood:

```bash
while true; do
  just rtp-capture 5600 /tmp/perception.jpg 800 600 5
  RESULT=$(just infer /tmp/perception.jpg "$PROMPT" 128 0.1)
  just nats-publish perception.vlm "{\"text\":$RESULT,\"ts\":$(date +%s)}"
  sleep 0.1
done
```

## Running it

```bash
tmux new -s perception
just perception-loop
# Ctrl-B D to detach
# tmux a -t perception to reattach
# Ctrl-C to stop
```

## Throughput

On Jetson Thor with Cosmos-Reason2-2B FP8:

| Prompt | Tokens out | FPS |
|---|---|---|
| "count people" | 16 | ~6 |
| "describe scene" | 64 | ~4 |
| "detailed JSON" | 128 | ~3 |
| "full narrative" | 256 | ~2 |

## Subscribing consumers

### Python (`nats-py`)

```python
import asyncio, json, nats

async def run():
    nc = await nats.connect("nats://thor.local:4222")
    async def handler(msg):
        ev = json.loads(msg.data)
        print(f"[{ev['ts']}] {ev['text']}")
    await nc.subscribe("perception.vlm", cb=handler)
    await asyncio.sleep(1_000_000)

asyncio.run(run())
```

### CLI

```bash
nats sub perception.vlm
```

### Node

```javascript
import { connect, StringCodec } from "nats";
const nc = await connect({ servers: "thor.local:4222" });
const sc = StringCodec();
for await (const m of nc.subscribe("perception.vlm")) {
  console.log(sc.decode(m.data));
}
```

## Tuning

| Goal | Change |
|---|---|
| Higher FPS | Lower `max_tokens`, shorter prompt, smaller image |
| Lower latency spikes | Set `nvpmodel -m 0` (MAXN_SUPER) |
| More stable output | `temperature=0.0`, add format-lock system prompt |
| Less CPU from sleep | `sleep 0` if you want max throughput |

## Multi-subject variant

You can run multiple loops publishing to different subjects:

```bash
tmux new -s peep1 'just perception-loop perception.people "count people"'
tmux new -s peep2 'just perception-loop perception.objects "list objects on table"'
```

## Graceful shutdown

```bash
tmux kill-session -t perception
just serve-stop
```
