# Versioning Guide

Chart Finder uses calendar-based versioning across every deployable surface. Each four-part version follows the pattern `YYYY.MM.mm.bb`:
- `YYYY` – four-digit year.
- `MM` – two-digit month.
- `mm` – logical release sequence within the month (start at 10 to keep room for patches).
- `bb` – global build sequence (start at 10000) to guarantee monotonically increasing identifiers.

Additional metadata captures the build origin:
- **Branch** – source branch that produced the artifact.
- **Comment** – optional release tag or human-readable descriptor.
- **Build Number** – UTC timestamp string (`yyyy-MM-ddTHH:mm:ssZ`) identifying the exact build. This value automatically bumps on a source file change.

## Updating Versions (General)

Run `./scripts/update-version.sh <target>` to stamp a new release:
- `backend` – updates `src/backend/Directory.Build.props`, which feeds all .NET assemblies. This also becomes the version stamp for all `infra` (Cloud provider) artifacts such as serverless functions, tables, etc.
- `frontend` – updates `frontend/version.json`, which feeds all frontend code (e.g. React or Flutter)
- *Note:* In both cases appropriate environment variables are automatically managed and set for the build system (see below for details).

The script prompts for version components, defaulting year/month to the current UTC calendar and preserving the existing comment (the backend uses the assembly description). The branch is auto-detected from the current Git checkout (or can be overridden via environment variable for detached builds). Supply environment variables to run non-interactively:

```bash
CHARTFINDER_BACKEND_VERSION=2025.02.101.10042 \
CHARTFINDER_BACKEND_BRANCH=main \
CHARTFINDER_BACKEND_BUILD_NUMBER=2025-02-01T12:34:56Z \
CHARTFINDER_BACKEND_COMMENT="January maintenance rollup" \
./scripts/update-version.sh backend
```

`CHARTFINDER_BACKEND_COMMENT` is optional. If unset, the script prompts and preserves the existing comment so the backend-specific build comment (distinct from the assembly description) can be managed per release.

## Querying Version (Backend)
The backend code is built using MSBuild which ingests the properties from the automatically-managed `src/backend/Directory.Build.props`. This results in a queryable Web service (hosted by the selected Cloud provider such as AWS or Azure) from the following endpoint: `GET /utils/v1/version`.

## Querying Version (Frontend)
Each frontend implementation is responsible for displaying the frontend version from the automatically-managed in `frontend/version.json`. The contents of `frontend/version.json` are translated by the build system into language-specific objects (example: `src/versionInfo.ts` for React; `lib/version_info.dart` for Flutter) and the actual frontend code always provides a "Version" screen which displays the frontend version and the backend version. (The backend version is queried directly from the selected Cloud provider.)
