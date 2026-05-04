# GEMINI.md Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a maintainer-focused `GEMINI.md` file that defines the templating contract and development workflow for the `gdc-baseline-iso` project.

**Architecture:** The `GEMINI.md` acts as a foundational mandate for both human maintainers and AI agents. It documents the "fragile" templating engine logic to prevent regressions and ensures consistent hardware profile integration.

**Tech Stack:** Markdown

---

### Task 1: Create Initial GEMINI.md with Core Mandates

**Files:**
- Create: `GEMINI.md`

- [ ] **Step 1: Define the core mandates and overview**

Create `GEMINI.md` with the following content:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add GEMINI.md
git commit -m "docs: create GEMINI.md with core mandates"
```

---

### Task 2: Document the Templating Contract

**Files:**
- Modify: `GEMINI.md`

- [ ] **Step 1: Add the Templating Engine section**

Append the following to `GEMINI.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add GEMINI.md
git commit -m "docs: document templating contract in GEMINI.md"
```

---

### Task 3: Document Hardware Profile and Verification Workflow

**Files:**
- Modify: `GEMINI.md`

- [ ] **Step 1: Add Profile and Workflow sections**

Append the following to `GEMINI.md`:

```markdown
## Hardware Profile Contract

To add support for new hardware:
1. Create a file named `settings-<model>.sh` in the root.
2. Ensure it defines all variables validated in `include.sh:validate_config()`.
3. Add the mapping to the `case` statement in `generate-isos.sh`.

## Verification Workflow

Before committing changes to templates or bash scripts:

1. **Dry-Run Validation:**
   Run `./generate-isos.sh -d -t single` (and other types) to verify template injection logic.
   ```bash
   ./generate-isos.sh -d -t single -h test-host
   ```

2. **Placeholder Audit:**
   After a build (or dry-run), check the generated `build/nocloud/user-data` for any unreplaced `__` strings:
   ```bash
   grep "__" build/nocloud/user-data
   ```
   *Expected: No matches.*

3. **Linting:**
   Ensure bash scripts are clean of syntax errors:
   ```bash
   bash -n *.sh
   ```
```

- [ ] **Step 2: Commit**

```bash
git add GEMINI.md
git commit -m "docs: finalize GEMINI.md with workflow and profile contracts"
```
