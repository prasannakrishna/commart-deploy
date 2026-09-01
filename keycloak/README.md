# Keycloak realm provisioning

Captures what was manually configured in the Keycloak admin console to make login/refresh
tokens work for this platform — previously undocumented anywhere, only living inside Keycloak's
own Postgres-backed state (`keycloakdb`).

## What's here

- **`import/scm-realm.json`** — a minimal realm-import file for the `scm` realm and its
  `scm-backend` client. The client is confidential (`directAccessGrantsEnabled: true`, so
  authService can do a Resource Owner Password Credentials grant on the user's behalf), and
  carries five custom protocol mappers (`roleType`, `domainType`, `tenantId`, `orgId`,
  `subscriptionType`) that stuff those user attributes into every access/ID token issued — this
  is what the frontend apps' JWT-decode logic (`StandaloneApp.jsx` etc.) actually reads.
  Realm-level token lifespans (`accessTokenLifespan: 300`, `ssoSessionIdleTimeout: 1800`,
  `ssoSessionMaxLifespan: 36000`) are captured too, though these are Keycloak's stock defaults,
  not an intentional customization as far as could be determined.

- **`provision-realm.sh`** — idempotent: checks whether the `scm` realm already exists on the
  target Keycloak, and only imports `scm-realm.json` if it's missing. Safe to run against an
  already-provisioned instance (no-ops) or a brand-new one (creates it). Use this as a deploy
  step after `docker compose up -d keycloak` on any new host, or after a disaster-recovery
  restore where Keycloak's data volume was lost.

  ```
  ./provision-realm.sh http://localhost:8080 <admin-password>
  ```

## What this does NOT cover

- The `keycloak` service definition itself (image, ports, `KC_DB`/`KEYCLOAK_ADMIN` env vars) —
  that's already in the main `docker-compose.yml`.
- Any users — this only provisions the realm/client shape, not actual user accounts.
- Auto-import on container boot — Keycloak supports `--import-realm` + mounting the file to
  `/opt/keycloak/data/import/`, which would run this automatically at startup instead of as a
  separate script step. Not wired into `docker-compose.yml` here since that changes the live
  Keycloak container's startup behavior — do that deliberately if you want it, not as a side
  effect of adding this file.

## Known issue, unrelated to this

The `command: start-dev` on the `keycloak` service runs Keycloak in development mode — its own
startup log says: *"Running the server in development mode. DO NOT use this configuration in
production."* Worth switching to `start --optimized` (or equivalent) with proper `KC_HOSTNAME`/
`KC_HTTPS` config at some point; not changed here since it's a separate, more involved decision.
