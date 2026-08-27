# Security policy

## Scope

DiveReady OW is an offline-first sample app. The public repository is intended to contain source code, tests, generic example content and documentation only. It must not contain credentials, signing assets, user data, private course media, phone numbers, device identifiers or local logs.

## Reporting a problem

Please do not publish secrets or personal information in an issue. For a suspected repository or dependency problem, use GitHub's private security advisory workflow or contact the maintainers privately through the repository's available channels. Include a minimal reproduction, affected revision and a safe description; redact paths, tokens, certificates and user content.

## Release hygiene

Before publishing a change, run the repository's tests and inspect the complete tracked-file list. Keep `.ipa`, `.app`, provisioning profiles, certificates, keychains, archives, screenshots containing people and exported logs out of Git history. If a secret is ever committed, revoke it first and then remove it from every reachable revision.
