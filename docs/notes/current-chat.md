# 2025-01-17

## Key Decisions
- Maintain a single repo while partitioning code into `src/backend`, `src/frontend`, and `src/infra`; mirror backend tests under `tests/backend`.
- Keep `ChartFinder.sln` at the repository root so future front-end stacks (Flutter, MAUI, etc.) stay decoupled.
- Treat DynamoDB as one implementation of a `IChartRepository` interface; plan for alternate providers and keep domain models AWS-agnostic.
- Record AWS SAM build outputs under `.aws-sam/` but keep them untracked; expand `.gitignore` with platform-specific artifacts when needed.
- Capture ongoing architecture and process notes inside `docs/notes/` so conversations remain versioned with the project.

## Next Actions
- Add `Chart` record and repository abstractions before wiring the DynamoDB implementation.
- Update `.gitignore` with the recommended entries for AWS SAM, macOS, IDE, and Flutter tooling.
- Scaffold minimal endpoints for storing and retrieving `Chart` entities once abstractions are in place.
- Run `codex chat` from a standalone terminal window for future sessions so the assistant stays visible alongside VS Code.

## 2025-01-18 Session Notes
- Confirmed AWS remains first-class target, followed by local/offline, then Azure (and possibly Google) adapters.
- Documented preference to keep AI-generated code out of the repo; assistant now supplies inline snippets only when asked.
- Settled on storing IAM templates under `infra/aws/iam/` with runtime copies mirrored under `.local/`; future sync script will hard-link static files and hydrate templated ones via folder-specific manifests.
- Agreed trust policies live in `infra/aws/iam/roles/` (e.g., `codebuild-exec-trust.json`) and permission sets in `infra/aws/iam/policies/` once hydrated.
