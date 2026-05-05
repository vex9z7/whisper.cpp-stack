# whisper.cpp-stack

Self-hosted Speech-to-Text with [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp), Docker Compose, and an OpenAI-compatible endpoint:

```http
POST /v1/audio/transcriptions
```

## Quick start

Requirements: Linux, Docker with Compose plugin, `curl`.

```bash
make init
make download
make up
```

## Project layout

```text
.env.example              # default config
Makefile                  # init, download, up
docker-compose.yml        # CPU/base service
docker-compose.vulkan.yml # AMD/Intel Vulkan override
docker-compose.cuda.yml   # NVIDIA CUDA override
models/                   # downloaded ggml model files
```

`WHISPER_MODEL` is the logical model name used by the download script. At runtime it maps to `models/ggml-<WHISPER_MODEL>.bin`.

Examples:

```text
WHISPER_MODEL=small          -> models/ggml-small.bin
WHISPER_MODEL=large-v3-turbo -> models/ggml-large-v3-turbo.bin
```

## Manual reachability test

From any machine with Bash and curl:

```bash
export WHISPER_BASE_URL=http://your-host:2022
curl -fsS "${WHISPER_BASE_URL}/v1/audio/transcriptions" -F "file=@/dev/fd/3;filename=jfk.wav;type=audio/wav" -F model=whisper-1 3< <(curl -LfsS https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav)
```
