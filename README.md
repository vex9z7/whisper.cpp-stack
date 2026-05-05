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
make smoke
```

Default service URL:

```text
http://127.0.0.1:2022
```

## Manual reachability test

From any machine with Bash and curl:

```bash
export WHISPER_BASE_URL=http://your-host:2022
curl -fsS "${WHISPER_BASE_URL}/v1/audio/transcriptions" -F "file=@/dev/fd/3;filename=jfk.wav;type=audio/wav" -F model=whisper-1 3< <(curl -LfsS https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav)
```

## Test and operate

```bash
make health
make smoke
make logs
make down
```

Use `small` for a faster test setup:

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

The runtime model file is derived as `ggml-<WHISPER_MODEL>.bin`.

## SELinux note

Fedora/Bazzite users: this repo uses `:Z` on `./models` mounts. If download still fails with `Permission denied`:

```bash
mkdir -p models
chcon -Rt container_file_t models 2>/dev/null || true
make download
```
