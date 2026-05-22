SHELL := /usr/bin/env bash

-include .env
export

MODEL ?= $(WHISPER_MODEL)
QUANT ?= $(WHISPER_QUANT)
BACKEND ?= $(or $(WHISPER_BACKEND),cpu)
COMPOSE_CMD ?= docker compose

IMAGE_REF ?= $(WHISPER_CPP_REF)

COMPOSE_FILES_cpu := -f docker-compose.yml
COMPOSE_FILES_vulkan := -f docker-compose.yml -f docker-compose.vulkan.yml
COMPOSE_FILES_cuda := -f docker-compose.yml -f docker-compose.cuda.yml

WHISPER_IMAGE_cpu := ghcr.io/ggml-org/whisper.cpp:main-$(IMAGE_REF)
WHISPER_IMAGE_vulkan := ghcr.io/ggml-org/whisper.cpp:main-vulkan-$(IMAGE_REF)
WHISPER_IMAGE_cuda := ghcr.io/ggml-org/whisper.cpp:main-cuda-$(IMAGE_REF)

SUPPORTED_BACKENDS := cpu vulkan cuda
SUPPORTED_QUANTS := q5_0 q5_1 q8_0
ifeq ($(filter $(BACKEND),$(SUPPORTED_BACKENDS)),)
$(error Unsupported BACKEND=$(BACKEND). Use one of: $(SUPPORTED_BACKENDS))
endif
ifneq ($(QUANT),)
ifeq ($(filter $(QUANT),$(SUPPORTED_QUANTS)),)
$(error Unsupported QUANT=$(QUANT). Leave empty or use one of: $(SUPPORTED_QUANTS))
endif
endif

COMPOSE_FILES := $(COMPOSE_FILES_$(BACKEND))
WHISPER_IMAGE := $(WHISPER_IMAGE_$(BACKEND))
MODEL_NAME := $(MODEL)
ifneq ($(QUANT),)
MODEL_NAME := $(MODEL)-$(QUANT)
endif
MODEL_FILE := ggml-$(MODEL_NAME).bin
MODEL_PATH := models/$(MODEL_FILE)
COMPOSE := WHISPER_MODEL_FILE=$(MODEL_FILE) WHISPER_CPP_REF=$(IMAGE_REF) $(COMPOSE_CMD) $(COMPOSE_FILES)

.PHONY: check download up down

check:
	@$(COMPOSE_CMD) version >/dev/null 2>&1 || (echo "Compose command failed: $(COMPOSE_CMD). Install Docker Compose plugin or run with COMPOSE_CMD=docker-compose" >&2; exit 2)
	@test -n "$(MODEL)" || (echo "MODEL is empty. Set WHISPER_MODEL in .env or pass MODEL=<name>" >&2; exit 2)
	@test -n "$(IMAGE_REF)" || (echo "WHISPER_CPP_REF is empty. Add it to .env or pass WHISPER_CPP_REF=<ref>" >&2; exit 2)
	@case "$(BACKEND)" in \
		cpu) echo "Backend cpu: no GPU device required" ;; \
		vulkan) test -e /dev/dri || (echo "Missing /dev/dri for Vulkan backend" >&2; exit 2); echo "Backend vulkan: /dev/dri found" ;; \
		cuda) command -v nvidia-smi >/dev/null || (echo "nvidia-smi not found; install NVIDIA driver/container toolkit for CUDA backend" >&2; exit 2); nvidia-smi -L ;; \
	esac

download:
	@test -n "$(MODEL)" || (echo "MODEL is empty. Set WHISPER_MODEL in .env or pass MODEL=<name>" >&2; exit 2)
	@test -n "$(IMAGE_REF)" || (echo "WHISPER_CPP_REF is empty. Add it to .env or pass WHISPER_CPP_REF=<ref>" >&2; exit 2)
	@if [ -f "$(MODEL_PATH)" ]; then \
		echo "Model already exists: $(MODEL_PATH)"; \
	else \
		docker run --rm \
			-v "$$(pwd)/models:/models:Z" \
			$(WHISPER_IMAGE) \
			"./models/download-ggml-model.sh $(MODEL_NAME) /models"; \
	fi
	ls -lh models

up: check download
	$(COMPOSE) up -d --force-recreate

down:
	$(COMPOSE) down
