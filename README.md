# whisper.cpp-stack

Self-hosted Speech-to-Text with [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp), Docker Compose, and an OpenAI-compatible endpoint:

```http
POST /v1/audio/transcriptions
```

## Quick start

Requirements: Linux, Docker with Compose plugin, `curl`.

```bash
make init      # create .env from .env.example and local folders
make download  # download WHISPER_MODEL into ./models
make up        # start whisper-server with the selected backend
```

## Manual reachability test

From any machine with Bash and curl:

```bash
export WHISPER_BASE_URL=http://your-host:2022
curl -fsS "${WHISPER_BASE_URL}/v1/audio/transcriptions" -F "file=@/dev/fd/3;filename=jfk.wav;type=audio/wav" -F model=whisper-1 3< <(curl -LfsS https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav)
```

## Models

Models are stored in `./models`. `WHISPER_MODEL` maps to `models/ggml-<WHISPER_MODEL>.bin`.

```text
WHISPER_MODEL=small          -> models/ggml-small.bin
WHISPER_MODEL=large-v3-turbo -> models/ggml-large-v3-turbo.bin
```
