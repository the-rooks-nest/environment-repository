# Environment Repository

This is the future home of the canonical Rook Environment Repository.

## Deployment note

`environments.the-rooks-nest.com` points at `http://localhost:18082`, so the production service should listen on port `18082`.

## GitHub Actions deployment secrets

This repo currently expects these GitHub Actions secrets:

- `ROOK_DEPLOY_HOST`
- `ROOK_DEPLOY_USER`
- `ROOK_DEPLOY_PORT`
- `ROOK_DEPLOY_SSH_KEY`
- `ROOK_CLOUDFLARE_ACCESS_CLIENT_ID`
- `ROOK_CLOUDFLARE_ACCESS_CLIENT_SECRET`

### Likely values / where to get them

#### `ROOK_DEPLOY_HOST`
- Where to get it: local SSH config / the working SSH host used with Cloudflare Access

#### `ROOK_DEPLOY_USER`
- Where to get it: `whoami` on the target machine, or local SSH config

#### `ROOK_DEPLOY_PORT`
- Likely value: `22`
- Where to get it: SSH config / server SSH setup

#### `ROOK_DEPLOY_SSH_KEY`
- Where to get it: copy the private key contents into the GitHub Actions secret

#### `ROOK_CLOUDFLARE_ACCESS_CLIENT_ID`
- Where to get it: currently sourced from the `Avalyfe.env` file
- Purpose: passed to `cloudflared access tcp --hostname ...` during GitHub Actions deploy

#### `ROOK_CLOUDFLARE_ACCESS_CLIENT_SECRET`
- Where to get it: currently sourced from the `Avalyfe.env` file
- Purpose: passed to `cloudflared access tcp --hostname ...` during GitHub Actions deploy

## Current deploy behavior

The deploy workflow:
- connects over SSH through Cloudflare Access
- bootstraps the repo checkout on the server if it is missing
- runs `deploy/deploy.sh`

The deploy script:
- fetches and resets to `main`
- creates/updates the Python virtualenv
- installs Python dependencies
- installs/updates the LaunchAgent plist
- restarts the service via `launchctl`

## Notes for future deploy setups

The public health endpoint is:
- `https://environments.the-rooks-nest.com/health`

The hostname `environment.the-rook-nest.com` is wrong and does not resolve. The working hostname is pluralized:
- `environments.the-rooks-nest.com`
