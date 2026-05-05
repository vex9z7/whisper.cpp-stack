# whisper.cpp-stack

A minimal self-hosted Speech-to-Text stack using [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp).

It runs `whisper-server` in Docker and exposes an OpenAI-compatible endpoint:

```http
POST /v1/audio/transcriptions
```

Default backend is CPU. Optional overrides support Vulkan for AMD/Intel GPUs and CUDA for NVIDIA GPUs. Models are downloaded explicitly into `./models` and mounted read-only.

## Quick start

Requirements: Linux, Docker Compose, `curl`.

```bash
make init
make download        # downloads WHISPER_MODEL from .env, default large-v3-turbo
make up              # CPU backend by default
make health
make smoke
```

Service URL:

```text
http://127.0.0.1:2022
```

Default `.env`:

```env
WHISPER_BACKEND=cpu
WHISPER_PORT=2022
WHISPER_MODEL=large-v3-turbo
WHISPER_PROCESSORS=1
WHISPER_THREADS=4
```

## Backends

```bash
make up              # CPU
make up-vulkan       # AMD/Intel GPU, requires /dev/dri
make up-cuda         # NVIDIA GPU, requires NVIDIA Container Toolkit
```

Or set `WHISPER_BACKEND=cpu|vulkan|cuda` in `.env` and run `make up`.

## Usage

```bash
curl http://127.0.0.1:2022/v1/audio/transcriptions \
  -F file=@recordings/test.wav \
  -F model=whisper-1
```

With language hint:

```bash
curl http://127.0.0.1:2022/v1/audio/transcriptions \
  -F file=@recordings/test.wav \
  -F model=whisper-1 \
  -F language=zh
```

Make helper:

```bash
make transcribe AUDIO=recordings/test.wav
WHISPER_LANGUAGE=zh make transcribe AUDIO=recordings/test.wav
```

## Test

```bash
make health
make smoke
make logs
```

For a lightweight smoke setup, use `small` only for testing:

```bash
make download MODEL=small
make up MODEL=small
make smoke
```

## Models

```bash
make download MODEL=base
make download MODEL=large-v3-turbo
```

To switch the default model:

```env
WHISPER_MODEL=base
```

Then restart:

```bash
make down
make up
```

The model file is derived as `ggml-<WHISPER_MODEL>.bin`.

## Notes

- Binds to `127.0.0.1` by default.
- This is chunked HTTP transcription, not token-level streaming ASR.
- For LAN access, prefer a private Docker network, reverse proxy, or VPN.
