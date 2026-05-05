# whisper.cpp-stack

A minimal self-hosted Speech-to-Text stack using [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp).

It runs `whisper-server` in Docker and exposes an OpenAI-compatible endpoint:

```http
POST /v1/audio/transcriptions
```

Default backend is CPU. Optional overrides support Vulkan for AMD/Intel GPUs and CUDA for NVIDIA GPUs. Models are downloaded explicitly into `./models` and mounted read-only.

## Quick start

Requirements: Linux, Docker with Compose plugin, `curl`. If your host uses standalone Compose, run with `COMPOSE_CMD=docker-compose`.

```bash
make init
make download        # downloads WHISPER_MODEL using selected backend image
make up              # CPU backend by default
make health
make smoke
```

Service URL:

```text
http://127.0.0.1:2022
```

To test from another machine on your LAN, set `WHISPER_HOST=0.0.0.0` in `.env` and restart with `make down && make up`.

Default `.env`:

```env
WHISPER_BACKEND=cpu
WHISPER_HOST=127.0.0.1
WHISPER_PORT=2022
WHISPER_MODEL=large-v3-turbo
WHISPER_PROCESSORS=1
WHISPER_THREADS=4
```

## Backends

```bash
make up                         # CPU, default
make up BACKEND=vulkan           # AMD/Intel GPU, requires /dev/dri
make up BACKEND=cuda             # NVIDIA GPU, requires NVIDIA Container Toolkit
```

Or set `WHISPER_BACKEND=cpu|vulkan|cuda` in `.env`; both `make download` and `make up` will use that backend image.

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

One-line smoke test from any machine with Bash and curl, without saving an audio file:

```bash
export WHISPER_BASE_URL=http://your-host:2022
curl -fsS "${WHISPER_BASE_URL}/v1/audio/transcriptions" -F "file=@/dev/fd/3;filename=jfk.wav;type=audio/wav" -F model=whisper-1 3< <(curl -LfsS https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav)
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

## Troubleshooting

On SELinux systems such as Fedora/Bazzite, bind-mounted model files need a container label. This repo uses `:Z` on the `./models` mount for both model download and runtime. If you still see `Permission denied` while downloading, reset the label and retry:

```bash
mkdir -p models
chcon -Rt container_file_t models 2>/dev/null || true
make download
```

## Notes

- Binds to `127.0.0.1` by default. Set `WHISPER_HOST=0.0.0.0` to expose it on your LAN.
- This is chunked HTTP transcription, not token-level streaming ASR.
- For LAN access, prefer a private Docker network, reverse proxy, or VPN.
