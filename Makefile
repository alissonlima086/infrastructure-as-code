SHELL := /usr/bin/env bash

ifneq (,$(wildcard .env))
include .env
export
endif

COMPOSE := docker compose --env-file .env -f docker-compose.yaml
ANSIBLE := ansible-playbook -i ansible/inventory.ini
export ANSIBLE_CONFIG := ansible/ansible.cfg

.PHONY: help env setup build up down logs ansible-deps provision deploy verify all check-env check-remote syntax-check

help:
	@echo "Local:  make env | build | up | down | logs"
	@echo "Remoto: make ansible-deps | provision | deploy | verify | all"
	@echo "Checks: make syntax-check"

env:
	@if [ -e .env ]; then \
		echo ".env já existe; nenhuma alteração foi feita."; \
	else \
		cp .env.example .env; \
		echo ".env criado a partir de .env.example. Revise os valores antes do deploy."; \
	fi

setup: env

check-env:
	@test -f .env || { echo "Arquivo .env ausente. Execute: make env" >&2; exit 1; }

check-remote: check-env
	@case "$(VPS_HOST)" in ""|"192.0.2.10") echo "Configure VPS_HOST no .env." >&2; exit 1;; esac
	@case "$(APP_DOMAIN)" in ""|"slides.example.com") echo "Configure APP_DOMAIN no .env." >&2; exit 1;; esac
	@test -n "$(VPS_USER)" || { echo "Configure VPS_USER no .env." >&2; exit 1; }
	@test -n "$(SSH_KEY_PATH)" || { echo "Configure SSH_KEY_PATH no .env." >&2; exit 1; }

build: check-env
	$(COMPOSE) build

up: check-env
	$(COMPOSE) up -d --build

down: check-env
	$(COMPOSE) down

logs: check-env
	$(COMPOSE) logs -f --tail=100

ansible-deps:
	ansible-galaxy collection install -r ansible/requirements.yaml

provision: check-remote ansible-deps
	$(ANSIBLE) ansible/provision.yaml

deploy: check-remote ansible-deps
	$(ANSIBLE) ansible/deploy.yaml

verify: check-remote ansible-deps
	$(ANSIBLE) ansible/verify.yaml

all: check-remote ansible-deps
	$(ANSIBLE) ansible/site.yaml

syntax-check: ansible-deps
	$(ANSIBLE) ansible/site.yaml --syntax-check
