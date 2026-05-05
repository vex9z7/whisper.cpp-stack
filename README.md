# whisper.cpp-stack

A small self-hosted Speech-to-Text stack based on [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp).

It runs `whisper-server` in Docker and exposes an OpenAI-compatible transcription endpoint:

```http
POST /v1/audio/transcriptions
```

Goals:

- simple local STT service for completed audio chunks
- CPU by default, with optional Vulkan and CUDA GPU backends
- explicit model management through a local `./models` directory
- no project-specific SDK, framework adapter, or model registry

This is not token-level streaming ASR. For realtime UX, send short completed chunks from your application/VAD pipeline.

## Requirements

- Linux
- Docker + Docker Compose plugin
- `curl`
- Optional for GPU:
  - Vulkan backend: `/dev/dri` and Vulkan-capable AMD/Intel driver
  - CUDA backend: NVIDIA driver + NVIDIA Container Toolkit

## Quick start

```bash
make init
make download MODEL=small
make up        # default backend is CPU
make health
make smoke
```

The service listens on localhost by default:

```text
http://127.0.0.1:2022
```

## Deploy

### CPU, default

```bash
make up
# or
make up BACKEND=cpu
```

### Vulkan, AMD/Intel GPU

```bash
make up BACKEND=vulkan
# or
make up-vulkan
```

### CUDA, NVIDIA GPU

```bash
make up BACKEND=cuda
# or
make up-cuda
```

To make a backend persistent, edit `.env`:

```bash
WHISPER_BACKEND=cpu      # cpu | vulkan | cuda
WHISPER_HOST_PORT=2022
WHISPER_MODEL_FILE=ggml-small.bin
WHISPER_PROCESSORS=1
WHISPER_THREADS=4
```

## Usage

Transcribe an audio file:

```bash
curl http://127.0.0.1:2022/v1/audio/transcriptions \
  -F file=@recordings/test.wav \
  -F model=whisper-1
```

With a language hint:

```bash
curl http://127.0.0.1:2022/v1/audio/transcriptions \
  -F file=@recordings/test.wav \
  -F model=whisper-1 \
  -F language=zh
```

Or use the Makefile helper:

```bash
make transcribe AUDIO=recordings/test.wav
WHISPER_LANGUAGE=zh make transcribe AUDIO=recordings/test.wav
```

## Testing

Health check:

```bash
make health
```

Smoke test with the public JFK sample from whisper.cpp:

```bash
make smoke
```

Inspect service state/logs:

```bash
make ps
make logs
```

## Model management

Models are explicit and local:

```bash
make download MODEL=base
make download MODEL=small
make download MODEL=large-v3-turbo
```

Downloaded files are stored in `./models` and mounted read-only into the container. Update `.env` when switching models:

```bash
WHISPER_MODEL_FILE=ggml-base.bin
```

Then restart:

```bash
make down
make up
```

## Common commands

```bash
make init
make download MODEL=small
make up                  # CPU default
make up-vulkan
make up-cuda
make down
make logs
make health
make smoke
make clean
```

## Safety defaults

- binds to `127.0.0.1` by default
- mounts `./models` read-only
- enables `no-new-privileges`
- uses container `/tmp` tmpfs

For LAN or production access, prefer a private Docker network, reverse proxy, or VPN rather than binding directly to `0.0.0.0`.
