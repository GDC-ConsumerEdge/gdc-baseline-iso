# Design Doc: GEMINI.md for gdc-baseline-iso

**Date:** 2026-04-28
**Topic:** Establishing Maintainer-Focused Rules and Templating Contract

## 1. Overview
The `gdc-baseline-iso` project relies on a multi-stage bash-based pipeline to generate opinionated Ubuntu ISOs. The core of this system is a fragile templating mechanism that uses `sed` to inject configuration into `cloud-init` user-data files. This document outlines the design for a `GEMINI.md` file that will guide maintainers and AI agents in safely extending and maintaining this project.

## 2. Goals
- Prevent regressions in the templating engine.
- Define a strict contract for placeholder variables.
- Standardize the process for adding new hardware profiles.
- Ensure consistent development workflows (dry-runs, mirror usage).

## 3. Architecture & Data Flow
The project follows a linear configuration injection path:
1. **Source:** `settings-*.sh` (Hardware profiles) and `settings.sh` (Global defaults).
2. **Orchestration:** `generate-isos.sh` (CLI argument parsing and environment setup).
3. **Execution:** `include.sh` (The `build_iso` and `xorriso_make` functions).
4. **Target:** `nocloud/user-data` (The final file injected into the ISO).

## 4. GEMINI.md Structure

### 4.1 Core Mandates (Highest Priority)
- **placeholder-integrity:** Placeholder strings (e.g., `__USER_NAME__`) are the "API" of the templates. Modifying a placeholder in a template *requires* a matching update in the `sed` logic within `include.sh`.
- **idempotency:** The `build/` directory is ephemeral. Never store persistent state there.

### 4.2 The Templating Contract
- Define the list of "Protected Placeholders":
    - `__KERNEL_FLAVOR__`
    - `__USER_NAME__`
    - `__PASSWORD__`
    - `__GRUB_PARTITION__`
    - `__PRIMARY_PARTITION__`
    - `__AUX_PARTITION__`
    - `__ETH_NAME__`
    - `__DISK_PATH_0__`
    - `__DISK_PATH_1__`
- Define the `ssh-authorized-keys` injection pattern (`__SSH_AUTH_KEYS__`).

### 4.3 Hardware Profile Contract
- New hardware profiles MUST be named `settings-<profile>.sh`.
- They MUST define all variables validated in `include.sh:validate_config()`.

### 4.4 Verification Workflow
- Before any PR/Commit:
    1. Run `./generate-isos.sh -d -t <type>` to verify template injection logic without full ISO build.
    2. Inspect generated `nocloud/user-data` for unreplaced `__` placeholders.

## 5. Success Criteria
- A `GEMINI.md` file exists in the root directory.
- The file accurately reflects the current bash script architecture.
- AI agents reading the file will understand they cannot change template variables without modifying the bash logic.
