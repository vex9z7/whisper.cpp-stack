# whisper.cpp-stack

Self-hosted Speech-to-Text with [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp), Docker Compose, and an OpenAI-compatible endpoint:

```http
POST /v1/audio/transcriptions
```

## Quick start

Requirements: Linux, Docker with Compose plugin, `curl`.

```bash
cp .env.example .env
make up        # downloads the configured model if missing, then starts whisper-server
make down      # stop the service
```

## Manual reachability test

From any machine with Bash and curl:

```bash
export WHISPER_BASE_URL=http://your-host:2022
curl -fsS "${WHISPER_BASE_URL}/v1/audio/transcriptions" -F "file=@/dev/fd/3;filename=jfk.wav;type=audio/wav" -F model=whisper-1 3< <(curl -LfsS https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav)
```

## Images

The upstream `whisper.cpp` container image is pinned by `WHISPER_CPP_REF` in `.env` so restarts do not silently pull a newer build. Update it intentionally when you want to move to a newer upstream image.

## Models

Models are stored in `./models`. `WHISPER_MODEL` is the logical model name; `WHISPER_QUANT` is an optional quantization suffix. By default `WHISPER_MODEL=large-v3-turbo` and `WHISPER_QUANT=` load the original/unquantized file.

```text
WHISPER_MODEL=large-v3-turbo, WHISPER_QUANT=     -> models/ggml-large-v3-turbo.bin
WHISPER_MODEL=large-v3-turbo, WHISPER_QUANT=q8_0 -> models/ggml-large-v3-turbo-q8_0.bin
WHISPER_MODEL=large-v3,       WHISPER_QUANT=q5_0 -> models/ggml-large-v3-q5_0.bin
```
