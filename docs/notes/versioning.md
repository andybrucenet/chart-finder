# Versioning Guide

Chart Finder uses calendar-based versioning across every deployable surface. Each four-part version follows the pattern `YYYY.MM.mm.bb`:
- `YYYY` – four-digit year.
- `MM` – two-digit month.
- `mm` – logical release sequence within the month (start at 10 to keep room for patches).
- `bb` – global build sequence (start at 10000) to guarantee monotonically increasing identifiers.

Additional metadata captures the build origin:
- **Branch** – source branch that produced the artifact.
- **Comment** – optional release tag or human-readable descriptor.
- **Build Number** – UTC timestamp string (`yyyy-MM-ddTHH:mm:ssZ`) identifying the exact build.

## Updating Versions

Run `./scripts/update-version.sh <target>` to stamp a new release:
- `backend` – updates `Directory.Build.props`, which feeds all .NET assemblies.
- Future targets (frontend, infra) will follow the same workflow.

The script prompts for version components, defaulting year/month to the current UTC calendar and preserving the existing comment (the backend uses the assembly description). The branch is auto-detected from the current Git checkout (or can be overridden via environment variable for detached builds). Supply environment variables to run non-interactively:

```bash
CHARTFINDER_BACKEND_VERSION=2025.02.101.10042 \
CHARTFINDER_BACKEND_BRANCH=main \
CHARTFINDER_BACKEND_BUILD_NUMBER=2025-02-01T12:34:56Z \
CHARTFINDER_BACKEND_COMMENT="January maintenance rollup" \
./scripts/update-version.sh backend
```

`CHARTFINDER_BACKEND_COMMENT` is optional. If unset, the script prompts and preserves the existing comment so the backend-specific build comment (distinct from the assembly description) can be managed per release. MSBuild ingests the resulting properties during build, and the backend exposes them at `GET /utils/v1/version`.
