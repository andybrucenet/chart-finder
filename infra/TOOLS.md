# Infrastructure Tooling

Core utilities expected across infrastructure scripts:
- `envsubst` – hydrate `.in` templates into `.local`.
- `rsync` – mirror static assets into hydrated directories.
- `jq` – JSON parsing for AWS CLI output.
- `dos2unix` – normalize line endings before hashing or uploading files.
- `shasum` – fingerprint TLS assets during setup.

Provider-specific CLIs and helpers are documented by each child directory (for example, `aws/TOOLS.md`).
