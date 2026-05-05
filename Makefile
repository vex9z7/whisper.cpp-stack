SHELL := /usr/bin/env bash

-include .env
export

MODEL ?= $(WHISPER_MODEL)
BACKEND ?= $(or $(WHISPER_BACKEND),cpu)
COMPOSE_CMD ?= docker compose

ifeq ($(BACKEND),cpu)
COMPOSE_FILES := -f docker-compose.yml
WHISPER_IMAGE := ghcr.io/ggml-org/whisper.cpp:main
else ifeq ($(BACKEND),vulkan)
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.vulkan.yml
WHISPER_IMAGE := ghcr.io/ggml-org/whisper.cpp:main-vulkan
else ifeq ($(BACKEND),cuda)
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.cuda.yml
WHISPER_IMAGE := ghcr.io/ggml-org/whisper.cpp:main-cuda
else
$(error Unsupported BACKEND=$(BACKEND). Use cpu, vulkan, or cuda)
endif

COMPOSE_ENV := WHISPER_MODEL_FILE=ggml-$(MODEL).bin
COMPOSE := $(COMPOSE_ENV) $(COMPOSE_CMD) $(COMPOSE_FILES)

.PHONY: init check download up

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

download:
	@test -n "$(MODEL)" || (echo "MODEL is empty. Set WHISPER_MODEL in .env or pass MODEL=<name>" >&2; exit 2)
	mkdir -p models
	docker run --rm \
		-v "$$(pwd)/models:/models:Z" \
		$(WHISPER_IMAGE) \
		"./models/download-ggml-model.sh $(MODEL) /models"
	ls -lh models

up: check
	$(COMPOSE) up -d --force-recreate
