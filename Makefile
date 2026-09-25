CLUSTER ?= devops-practice
IMAGE   ?= task-api:local

.PHONY: help test run docker-build docker-run compose-up compose-down \
	    tf-local-init tf-local-apply tf-local-destroy kind-load k8s-local-deploy k8s-local-delete

help:
	@grep -E '^[a-zA-Z_-]+:' Makefile | cut -d: -f1 | sort

test:
	cd app && pip install -q -r requirements-dev.txt && pytest -v

run:
	cd app && pip install -q -r requirements.txt && python -m flask --app main run --port 8000

docker-build:
	docker build --build-arg APP_VERSION=local -t $(IMAGE) .

docker-run: docker-build
	docker run --rm -p 8000:8000 $(IMAGE)

compose-up:
	docker compose up --build -d

compose-down:
	docker compose down

tf-local-init:
	cd terraform/local-kind && terraform init

tf-local-apply: tf-local-init
	cd terraform/local-kind && terraform apply

tf-local-destroy:
	cd terraform/local-kind && terraform destroy

kind-load: docker-build
	kind load docker-image $(IMAGE) --name $(CLUSTER)

k8s-local-deploy: kind-load
	kubectl apply -k k8s/overlays/local
	kubectl -n task-api rollout status deployment/task-api
	@echo "App: http://localhost:8080"

k8s-local-delete:
	kubectl delete -k k8s/overlays/local
