# Project Mandates: gdc-baseline-iso

This project automates the creation of headless bootable Ubuntu ISOs. It uses a custom bash-based templating engine to inject `cloud-init` configuration into the ISO during the build process.

## Core Mandates

1. **Placeholder Integrity:** Placeholder strings in templates (e.g., `__USER_NAME__`) are the "API" of the project.
   - NEVER rename a placeholder in `template-nocloud/` without a corresponding update to the `sed` logic in `include.sh`.
   - All placeholders MUST follow the `__VARIABLE_NAME__` convention.

2. **Idempotency:**
   - The `build/` and `iso-outputs/` directories are ephemeral and ignored by git.
   - Never store persistent configuration or state in these directories.

3. **No Interactive Prompts:**
   - The generated ISOs are designed for "wipe-and-install" automation.
   - Changes to `user-data` must maintain the `autoinstall` and `noprompt` behavior.
