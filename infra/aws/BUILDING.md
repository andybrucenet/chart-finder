# Building & Deploying

Use the helper scripts from the repo root so hydrated `.local` configs stay in sync:
1. `./scripts/setup-dev-env.sh` (or `./scripts/sync-configs.sh`) – refresh `.local/infra/aws/**`.
2. `./scripts/aws-sam-preflight.sh` – validate templates before build/deploy.
3. `./scripts/aws-sam-deploy.sh build` – run `sam build` + `sam deploy` for the active billing environment.
4. Inspect stack outputs with `./scripts/cf-run-cmd.sh aws cloudformation describe-stacks ...` as needed.

Day-to-day troubleshooting lives in `docs/cookbooks/backend/aws.md`.
