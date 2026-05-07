"""Cosmos-Reason2 VLM inference against the local TRT-Edge-LLM server."""
from __future__ import annotations

import base64
import time
from pathlib import Path

import requests
from strands import tool

from ._common import ok, err, env_default


DEFAULT_SERVER = env_default("COSMOS_VLM_URL", "http://127.0.0.1:8080/v1/chat/completions")


@tool
def cosmos_inference(
    prompt: str,
    image_path: str = "",
    image_b64: str = "",
    server_url: str = "",
    max_tokens: int = 256,
    temperature: float = 0.2,
    system_prompt: str = "",
    return_image: bool = False,
) -> dict:
    """Run Cosmos-Reason2 VLM inference: image + prompt → structured scene description.

    Uses the local TRT-Edge-LLM HTTP server (FP8-quantized on Jetson Thor).
    Models: nvidia/Cosmos-Reason2-2B. See cookbook intbot_edge_vlm recipe.

    Args:
        prompt: User instruction (e.g. "count people, report clothing").
        image_path: Path to JPEG/PNG on disk. Mutually exclusive with image_b64.
        image_b64: Base64 image (alternative to image_path).
        server_url: Override the VLM endpoint. Default: env COSMOS_VLM_URL.
        max_tokens: Token cap (keep low for Thor latency).
        temperature: Sampling temperature (0.0-1.0). Use 0.0-0.2 for perception.
        system_prompt: Optional system prompt (prompt engineering).
        return_image: If True, include the input image in the response for the agent to see.

    Returns:
        ToolResult with text (VLM output), json (metrics), and optionally the input image.
    """
    url = server_url or DEFAULT_SERVER

    if image_path and image_b64:
        return err("provide exactly one of image_path or image_b64")
    if not image_path and not image_b64:
        return err("image_path or image_b64 is required")

    image_bytes: bytes | None = None
    if image_path:
        p = Path(image_path).expanduser()
        if not p.exists():
            return err(f"image not found: {p}")
        image_bytes = p.read_bytes()
        image_b64 = base64.b64encode(image_bytes).decode("ascii")

    messages: list[dict] = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({
        "role": "user",
        "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url",
             "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"}},
        ],
    })
    payload = {
        "model": "trt-edgellm",
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }

    try:
        t0 = time.time()
        r = requests.post(url, json=payload, timeout=60)
        latency_ms = int((time.time() - t0) * 1000)
        r.raise_for_status()
        data = r.json()
        text = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        if not text:
            text = str(data)

        result_data = {
            "latency_ms": latency_ms,
            "server_infer_ms": data.get("usage", {}).get("server_infer_ms"),
            "server_url": url,
            "prompt_chars": len(prompt),
            "output_chars": len(text),
        }

        return ok(
            text=f"VLM → {text}\n\n(latency: {latency_ms}ms)",
            data=result_data,
            image_bytes=image_bytes if (return_image and image_bytes) else None,
            image_format="jpeg",
        )
    except requests.exceptions.ConnectionError:
        return err(
            f"cannot reach VLM server at {url}. "
            f"Start it with cosmos_serve(action='start', ...)",
            data={"url": url},
        )
    except Exception as e:  # noqa: BLE001
        return err(f"{type(e).__name__}: {e}", data={"url": url})
