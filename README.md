# DevOps Practice Lab

A tiny Flask "Task API" wrapped in everything you want to practice: **Docker, Kubernetes (kustomize), Terraform, and GitHub Actions**.
The app is intentionally simple so the tooling is the star.

```
.
├── app/                    # Flask API + tests
├── Dockerfile              # multi-stage, non-root
├── docker-compose.yml
├── k8s/
│   ├── base/               # namespace, configmap, deployment, service
│   ├── overlays/local/     # kind: 1 replica, NodePort 30080
│   ├── overlays/eks/       # AWS: LoadBalancer service
│   └── extras/hpa.yaml     # exercise
├── terraform/
│   ├── local-kind/         # FREE: creates a kind cluster on your machine
│   └── aws/                # VPC + EKS + ECR + GitHub OIDC role (costs money)
├── .github/workflows/
│   ├── ci.yml              # lint, test, docker build, terraform validate, kind smoke test
│   └── deploy.yml          # build -> ECR -> deploy to EKS (opt-in)
└── Makefile
```

API: `GET /` · `GET /health` · `GET /ready` · `GET|POST /tasks` · `DELETE /tasks/{id}`

## Prerequisites
git, Python 3.12, Docker, kubectl, [kind](https://kind.sigs.k8s.io), Terraform >= 1.6.
For Phase 5 only: an AWS account and AWS CLI.

## Phase 0 - Put it on GitHub
```bash
git init && git add . && git commit -m "Initial commit"
gh repo create devops-practice-lab --public --source=. --push   # or create it in the UI
```
Open the **Actions** tab: `CI` should run and go green (the `deploy` workflow skips itself until Phase 5).

## Phase 1 - Run the app
```bash
make test
make run                 # http://localhost:8000
curl -X POST localhost:8000/tasks -H 'Content-Type: application/json' -d '{"title":"learn k8s"}'
```

## Phase 2 - Docker
```bash
make docker-run          # or: make compose-up
docker history task-api:local     # look at layers
docker exec -it <container> id    # confirm non-root (uid 10001)
```

## Phase 3 - Terraform (local) + Kubernetes
```bash
make tf-local-apply                       # creates kind cluster "devops-practice" (1 control-plane, 1 worker)
export KUBECONFIG=$(cd terraform/local-kind && terraform output -raw kubeconfig_path)
make k8s-local-deploy                     # build, load into kind, kubectl apply -k
curl localhost:8080/health
kubectl -n task-api get pods,svc
```
Tear down: `make k8s-local-delete && make tf-local-destroy`

## Phase 4 - Watch the pipeline do the same thing
Open a pull request. `ci.yml` builds the image, spins up a throwaway kind cluster **inside the GitHub runner**, deploys the local overlay and curls it. Break something on purpose (wrong probe path, bad image name) and read the failure output.

## Phase 5 - Real cloud deploy on AWS (costs roughly $0.15-0.25/hour; destroy when done)
1. Provision:
   ```bash
   cd terraform/aws
   cp terraform.tfvars.example terraform.tfvars   # set github_repo = "you/devops-practice-lab"
   terraform init && terraform plan && terraform apply
   ```
2. In GitHub -> Settings -> Secrets and variables -> Actions -> **Variables**, add:

   | Variable | Value (from `terraform output`) |
   |---|---|
   | `ENABLE_AWS_DEPLOY` | `true` |
   | `AWS_REGION` | e.g. `ap-southeast-1` |
   | `AWS_ROLE_ARN` | `github_actions_role_arn` |
   | `ECR_REPOSITORY_URL` | `ecr_repository_url` |
   | `EKS_CLUSTER_NAME` | `eks_cluster_name` |
3. Push to `main` (or run the workflow manually). It builds, pushes to ECR tagged with the commit SHA, and rolls out to EKS.
4. Get the URL: `kubectl -n task-api get svc task-api`
5. **Clean up**: `kubectl delete -k k8s/overlays/eks` (removes the load balancer first), then `terraform destroy`.

No AWS keys are stored in GitHub: the pipeline uses OIDC, and the IAM trust policy only allows the `main` branch of your repo.

## Exercises (roughly easy -> hard)
- [ ] Add a `/version` endpoint, bump the code, and watch a rolling update (`kubectl rollout status`, `kubectl rollout undo`).
- [ ] Scale to 3 replicas and `POST /tasks` repeatedly. Why do tasks appear and disappear? (In-memory state per pod.) Fix it by adding **Postgres or Redis** to compose, then to k8s.
- [ ] Move `APP_MESSAGE` from the ConfigMap to a Secret; mount it as a file instead of an env var.
- [ ] Install metrics-server and apply `k8s/extras/hpa.yaml`; load test with `hey` or `k6` and watch it scale.
- [ ] Add an Ingress (ingress-nginx on kind, AWS Load Balancer Controller on EKS).
- [ ] Add a Trivy image scan and a `terraform plan` comment on PRs to `ci.yml`.
- [ ] Move Terraform state to S3 with locking (see the commented `backend` block).
- [ ] Split `overlays/eks` into `staging` and `prod`; use GitHub Environments with required approval (hint: the OIDC `sub` claim changes to `environment:<name>`, so update the IAM trust policy).
- [ ] Publish the image to GHCR and add Dependabot for Actions, pip and Terraform.
- [ ] Replace `kubectl apply` with Argo CD or Flux (GitOps).
- [ ] Add Helm: convert the base manifests into a chart.

## Troubleshooting
- `ImagePullBackOff` on kind -> you forgot `make kind-load`, or the tag doesn't match the overlay (`local`).
- `deploy.yml` can't assume the role -> the trust policy needs the exact `owner/repo` and the workflow must run on `main`.
- `kustomize: command not found` in the deploy job -> add a kustomize setup step; the GitHub-hosted Ubuntu runners normally include it.
- Pinned versions (EKS `1.33`, modules `~> 20`/`~> 5`, action versions) will age. Check current releases and bump.
