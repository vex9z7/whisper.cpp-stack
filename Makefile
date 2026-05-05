SHELL := /usr/bin/env bash

-include .env
export

MODEL ?= $(WHISPER_MODEL)
AUDIO ?= examples/jfk.wav
BACKEND ?= $(or $(WHISPER_BACKEND),cpu)
PORT ?= $(or $(WHISPER_PORT),2022)
BASE_URL ?= http://127.0.0.1:$(PORT)
DOWNLOAD_IMAGE ?= ghcr.io/ggml-org/whisper.cpp:main
COMPOSE_CMD ?= docker compose

ifeq ($(BACKEND),cpu)
COMPOSE_FILES := -f docker-compose.yml
else ifeq ($(BACKEND),vulkan)
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.vulkan.yml
else ifeq ($(BACKEND),cuda)
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.cuda.yml
else
$(error Unsupported BACKEND=$(BACKEND). Use cpu, vulkan, or cuda)
endif

COMPOSE_ENV := WHISPER_MODEL_FILE=ggml-$(MODEL).bin
COMPOSE := $(COMPOSE_ENV) $(COMPOSE_CMD) $(COMPOSE_FILES)

.PHONY: init check download up down logs health transcribe smoke clean

init:
	cp -n .env.example .env || true
	mkdir -p models recordings examples

check:
	@$(COMPOSE_CMD) version >/dev/null 2>&1 || (echo "Compose command failed: $(COMPOSE_CMD). Install Docker Compose plugin or run with COMPOSE_CMD=docker-compose" >&2; exit 2)
	@case "$(BACKEND)" in \
		cpu) echo "Backend cpu: no GPU device required" ;; \
		vulkan) test -e /dev/dri || (echo "Missing /dev/dri for Vulkan backend" >&2; exit 2); echo "Backend vulkan: /dev/dri found" ;; \
		cuda) command -v nvidia-smi >/dev/null || (echo "nvidia-smi not found; install NVIDIA driver/container toolkit for CUDA backend" >&2; exit 2); nvidia-smi -L ;; \
	esac
	@test -n "$(MODEL)" || (echo "MODEL is empty. Set WHISPER_MODEL in .env or pass MODEL=<name>" >&2; exit 2)

# Download ggml model into ./models, e.g. make download MODEL=base
download:
	@test -n "$(MODEL)" || (echo "MODEL is empty. Set WHISPER_MODEL in .env or pass MODEL=<name>" >&2; exit 2)
	mkdir -p models
	docker run --rm \
		-v "$$(pwd)/models:/models:Z" \
		$(DOWNLOAD_IMAGE) \
		"./models/download-ggml-model.sh $(MODEL) /models"
	ls -lh models

up: check
	$(COMPOSE) up -d --force-recreate

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f whisper

health:
	@code=$$(curl -sS -o /dev/null -w "%{http_code}" -X POST "$(BASE_URL)/v1/audio/transcriptions" -F "model=whisper-1" || true); \
	if [ "$$code" = "000" ]; then \
		echo "whisper.cpp server is not reachable: $(BASE_URL)" >&2; \
		exit 1; \
	fi
	@echo "whisper.cpp server is reachable: $(BASE_URL)"

transcribe:
	@test -f "$(AUDIO)" || (echo "Audio file not found: $(AUDIO)" >&2; exit 2)
	curl -fsS "$(BASE_URL)/v1/audio/transcriptions" \
		-F "file=@$(AUDIO)" \
		-F "model=whisper-1" \
		$${WHISPER_LANGUAGE:+-F language=$$WHISPER_LANGUAGE}
	@echo

smoke:
	mkdir -p examples
	@if [ ! -f examples/jfk.wav ]; then \
		echo "Downloading public smoke-test sample ..."; \
		curl -LfsS -o examples/jfk.wav https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav; \
	fi
	$(MAKE) health
	$(MAKE) transcribe AUDIO=examples/jfk.wav

clean:
	rm -rf .pytest_cache
	find recordings examples -mindepth 1 -delete
