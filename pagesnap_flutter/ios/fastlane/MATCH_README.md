# Using fastlane `match` for code signing (recommended)

This project supports using `fastlane match` to manage iOS certificates and provisioning
profiles in a private git repository. Using `match` prevents the CI from creating new
distribution certificates (which are limited by Apple) and makes signing reproducible.

Recommended GitHub Actions secrets (Repository -> Settings -> Secrets & variables):

- `MATCH_GIT_URL` — HTTPS URL of your private certificates git repo. Example:
  `https://github.com/your-org/ios-certs.git`.
- `MATCH_PASSWORD` — password used to encrypt the repository (used by `match`).
- `MATCH_READONLY` — set to `true` in CI if you only want to fetch (recommended).

Fastlane configuration in `Fastfile` will use `ENV['MATCH_GIT_URL']` when present.
To enable `match` in CI:

1. Create a private repo to store certificates: `match` will initialize it.
2. Add the three secrets above to this repository.
3. Re-run the `iOS TestFlight Deployment` workflow (re-run failed jobs).

If you cannot use `match`, the pipeline will fall back to `cert`/`sigh`, which may
fail if the Apple account has already reached the distribution certificate limit.

More info: https://docs.fastlane.tools/actions/match/
