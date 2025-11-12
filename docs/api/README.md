# API Contracts

- `backend.v1.json` – OpenAPI specification generated from the Chart Finder backend (`make backend-swagger`).
- Regenerate after modifying controllers or request/response contracts:
  1. `make backend build` (or `make backend-swagger` to build + export in one step).
  2. Commit the updated JSON alongside the related code changes.
- Client SDKs should consume this checked-in spec instead of hitting a live service at build time.
