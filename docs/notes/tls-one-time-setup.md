# Chart Finder TLS Bootstrap

One-time steps for provisioning the wildcard certificate that backs Chart Finder endpoints (`*.chart-finder.app`, etc.). Reuse this guide for future backend/mobile apps that sit behind the same domain.

## Directory Layout (macOS)

1. Create a secure working directory (replace `andy` if needed):
   ```bash
   mkdir -p ~/Documents/Personal/andy/certs/ssl/chart-finder/{config,work,logs}
   chmod 700 ~/Documents/Personal/andy/certs/ssl/chart-finder ~/Documents/Personal/andy/certs/ssl/chart-finder/{config,work,logs}
   ```
   Certbot will write the private key here. Keep it out of git/backup tools you don’t control.

## Issue the Wildcard Certificate (Let’s Encrypt)

1. Install Certbot (Homebrew):
   ```bash
   brew install certbot
   ```
2. Request `chart-finder.app` + `*.chart-finder.app` using the DNS-01 challenge. Example with Cloudflare’s DNS API:
   1. In the Cloudflare dashboard, go to **My Profile → API Tokens → Create Token**.
   2. Choose the **Edit zone DNS** template, scope it to the `chart-finder.app` zone, and create the token.
   3. Save the token to `~/.cloudflare-api-token.ini` with permissions `chmod 600`:
      ```
      dns_cloudflare_api_token = <token value>
      ```
   4. Run Certbot:
      ```bash
      certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials ~/.cloudflare-api-token.ini \
        -d chart-finder.app \
        -d '*.chart-finder.app' \
        --config-dir ~/Documents/Personal/andy/certs/ssl/chart-finder/config \
        --work-dir ~/Documents/Personal/andy/certs/ssl/chart-finder/work \
        --logs-dir ~/Documents/Personal/andy/certs/ssl/chart-finder/logs
      ```
   - If you use a different DNS provider, swap the Certbot plugin or complete the TXT records manually when prompted.
3. On success, Certbot writes:
   - `~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/cert.pem`
   - `~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/chain.pem`
   - `~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/privkey.pem`
   Lock down permissions (`chmod 600`) if needed.

## Import into Cloud Providers

### AWS (API Gateway, CloudFront)

1. Import the certificate into ACM (same region as the custom domain):
   ```bash
   aws acm import-certificate \
     --certificate fileb://~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/cert.pem \
     --private-key fileb://~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/privkey.pem \
     --certificate-chain fileb://~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/chain.pem
   ```
2. Record the returned ARN (e.g., `CF_LOCAL_TLS_CERT_ARN`) for custom domain mappings.

### Azure (future)

1. Convert to PKCS#12 for Key Vault/App Service:
   ```bash
   openssl pkcs12 -export \
     -in ~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/fullchain.pem \
     -inkey ~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/privkey.pem \
     -out ~/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/chart-finder.pfx \
     -name chart-finder-wildcard
   ```
2. Import the `.pfx` into Azure Key Vault or App Service when provisioning the alternate backend.

## Automate Renewal

Let’s Encrypt certificates expire every 90 days. Schedule `certbot renew` and re-import the certs:

```bash
0 3 * * * /opt/homebrew/bin/certbot renew \
  --dns-cloudflare \
  --dns-cloudflare-credentials /Users/andy/.cloudflare-api-token.ini \
  --config-dir /Users/andy/Documents/Personal/andy/certs/ssl/chart-finder/config \
  --work-dir /Users/andy/Documents/Personal/andy/certs/ssl/chart-finder/work \
  --logs-dir /Users/andy/Documents/Personal/andy/certs/ssl/chart-finder/logs \
  && /opt/homebrew/bin/aws acm import-certificate --certificate fileb:///Users/andy/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/cert.pem --private-key fileb:///Users/andy/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/privkey.pem --certificate-chain fileb:///Users/andy/Documents/Personal/andy/certs/ssl/chart-finder/config/live/chart-finder.app/chain.pem --certificate-arn <existing-arn>
```

- Replace `andy` and `<existing-arn>` with your values.
- Convert the renewed cert to `.pfx` and re-upload to Azure as needed.
- Consider wrapping the logic in a script (`renew.sh`) and invoking that from cron or a macOS LaunchAgent for cleaner logging.

## Project Integration

- Add environment variables such as:
  - `CF_LOCAL_DOMAIN` → canonical domain (e.g., `chart-finder.app`).
  - `CF_LOCAL_TLS_CERT_PATH` → absolute path to `cert.pem`.
  - `CF_LOCAL_TLS_CHAIN_PATH` → absolute path to `chain.pem`.
  - `CF_LOCAL_TLS_KEY_PATH` → absolute path to `privkey.pem`.
  - `CF_LOCAL_TLS_CERT_ARN` → ACM ARN returned during import.
- Never store the private key or `.pfx` inside the repository. Use the secure path above or a secrets manager.
- When provisioning API Gateway custom domains (`dev-api.chart-finder.com`, etc.), reference `CF_LOCAL_TLS_CERT_ARN` and map the appropriate stages.

## Cloudflare DNS Automation

After deployment, update the Cloudflare DNS zone so the environment-specific subdomain (e.g., `sab-u-dev-api.chart-finder.app`) points at the API Gateway domain.

1. **Discover the target in CloudFormation:**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name cf-sab-u-dev \
     --query "Stacks[0].Outputs[?OutputKey=='ApiCustomDomainTarget'].OutputValue" \
     --output text
   ```
   Store the value (e.g., `d-2cawsx1lme.execute-api.us-east-2.amazonaws.com`).

2. **Look up the Cloudflare zone ID (one-time per domain):**
   ```bash
   curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=chart-finder.app" \
     -H "Authorization: Bearer ${CF_API_TOKEN}" \
     -H "Content-Type: application/json"
   ```
   Record the `id` field (call it `CF_ZONE_ID`).

3. **Upsert the CNAME record for the environment:**
   ```bash
   curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
     -H "Authorization: Bearer ${CF_API_TOKEN}" \
     -H "Content-Type: application/json" \
     --data "{
       \"type\": \"CNAME\",
       \"name\": \"${CF_LOCAL_ENV_ID%-api}-api\",
       \"content\": \"${API_CUSTOM_DOMAIN_TARGET}\",
       \"ttl\": 300,
       \"proxied\": false
     }"
   ```
   * If the record doesn’t exist yet, use `POST .../dns_records` (the response returns the record ID).  
   * Set `"proxied": true` only if Cloudflare should front the API; otherwise keep it `false` for direct access.

4. **Cache the mapping** under `.local/state/cloudflare-dns.json` (or similar) so future deploys can detect when the target changes and re-run the update.

Repeat this for other services (e.g., `*-web`, `*-oauth`) as they come online.

Keep this procedure updated as you automate renewals or expand to additional cloud providers.
