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
## The Templating Engine Contract

The build pipeline follows this path:
`settings-*.sh` (Profile) -> `generate-isos.sh` (CLI) -> `include.sh` (Injection) -> `nocloud/user-data` (Target).

### Protected Placeholders
Any template used by `generate-isos.sh` MUST support these variables:

| Placeholder | Source Variable | Description |
|-------------|-----------------|-------------|
| `__USER_NAME__` | `$OPT_USER` | Default admin username |
| `__PASSWORD__` | `$ENCRYPTED_USER_PASSWORD` | Encrypted SHA-512 password |
| `__KERNEL_FLAVOR__` | `$FLAVOR` | generic or hwe |
| `__GRUB_PARTITION__` | `$GRUB_PARTITION` | Size (e.g., 1GB) |
| `__PRIMARY_PARTITION__` | `$PRIMARY_PARTITION` | Size or -1 |
| `__AUX_PARTITION__` | `$AUX_PARTITION` | Size or -1 |
| `__ETH_NAME__` | `$ETH_NAME` | Interface matcher (e.g., en*) |
| `__DISK_PATH_0__` | `$DISK_0_PATH` | Primary OS disk |
| `__DISK_PATH_1__` | `$DISK_1_PATH` | Secondary data disk |
| `__SSH_AUTH_KEYS__` | `./pub_keys` | Injected as a cloud-init list |

### Hardware Profile Contract
- New hardware profiles MUST be named settings-<profile>.sh.
- They MUST define all variables validated in include.sh:validate_config().
