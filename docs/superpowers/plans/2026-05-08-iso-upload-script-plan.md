# ISO Upload Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a bash script (`upload-isos.sh`) that uploads generated ISO files to a Synology NAS using `smbclient`, configurable via environment variables including wildcard matching.

**Architecture:** A single, standalone bash script. It validates environment variables, checks for dependencies, finds files matching a pattern, and loops through them to upload via `smbclient`.

**Tech Stack:** Bash, `smbclient`.

---

### File Structure
- Create: `upload-isos.sh` (The main script)

### Task 1: Create script scaffold and environment variable parsing

**Files:**
- Create: `upload-isos.sh`

- [ ] **Step 1: Write the initial script structure and argument parsing**

```bash
#!/bin/bash

# upload-isos.sh
# Uploads generated ISOs to a Synology NAS via SMB.

# Default values
NAS_HOST="${NAS_HOST:-storage.ensor-labs.com}"
NAS_SHARE="${NAS_SHARE:-iso_share}"
ISO_DIR="${ISO_DIR:-./iso-outputs}"
ISO_PATTERN="${ISO_PATTERN:-*.iso}"

# Error handling
set -e

function output_error() {
    echo -e "\033[1;91mError: $1\033[0m" >&2
}

function output_msg() {
    echo -e "\033[1;96m$1\033[0m"
}

# Validation
if [[ -z "${NAS_USER}" ]]; then
    output_error "Environment variable NAS_USER is required."
    exit 1
fi

if [[ -z "${NAS_PASS}" ]]; then
    output_error "Environment variable NAS_PASS is required."
    exit 1
fi

if [[ ! -d "${ISO_DIR}" ]]; then
    output_error "Directory ISO_DIR (${ISO_DIR}) does not exist."
    exit 1
fi

output_msg "Configuration loaded successfully."
output_msg "Target: //${NAS_HOST}/${NAS_SHARE}"
output_msg "Source: ${ISO_DIR}/${ISO_PATTERN}"
```

- [ ] **Step 2: Make the script executable**

Run: `chmod +x upload-isos.sh`
Expected: No output.

- [ ] **Step 3: Test missing variables**

Run: `./upload-isos.sh`
Expected: FAIL with `Error: Environment variable NAS_USER is required.`

- [ ] **Step 4: Test directory validation**

Run: `NAS_USER=user NAS_PASS=pass ISO_DIR=/nonexistent ./upload-isos.sh`
Expected: FAIL with `Error: Directory ISO_DIR (/nonexistent) does not exist.`

- [ ] **Step 5: Test successful validation**

Run: `mkdir -p ./iso-outputs && NAS_USER=user NAS_PASS=pass ./upload-isos.sh`
Expected: PASS with `Configuration loaded successfully.` messages.

- [ ] **Step 6: Commit**

```bash
git add upload-isos.sh
git commit -m "feat: add initial upload-isos.sh with validation"
```

### Task 2: Add dependency check for smbclient

**Files:**
- Modify: `upload-isos.sh`

- [ ] **Step 1: Add dependency check function**

Insert after the `output_msg` function:

```bash
function check_dependencies() {
    if ! command -v smbclient &> /dev/null; then
        output_error "Required command 'smbclient' is not installed."
        echo "On Debian/Ubuntu, install it using: sudo apt install smbclient"
        exit 1
    fi
}
```

- [ ] **Step 2: Call the dependency check**

Add the call right after the existing validation block (before the success messages):

```bash
check_dependencies
```

- [ ] **Step 3: Test dependency check (Happy Path)**

Run: `NAS_USER=user NAS_PASS=pass ./upload-isos.sh`
Expected: PASS with success messages (assuming `smbclient` is installed locally).

- [ ] **Step 4: Commit**

```bash
git add upload-isos.sh
git commit -m "feat: add smbclient dependency check to upload script"
```

### Task 3: Implement file finding and upload loop

**Files:**
- Modify: `upload-isos.sh`

- [ ] **Step 1: Implement the upload logic**

Append to the bottom of `upload-isos.sh`:

```bash
# Find files and upload
# Use a subshell to avoid changing the script's working directory
(
    cd "${ISO_DIR}"
    
    # Expand the pattern and check if files exist
    # Enable nullglob so unmatched patterns return empty instead of the literal string
    shopt -s nullglob
    files=(${ISO_PATTERN})
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        output_msg "No files found matching '${ISO_PATTERN}' in ${ISO_DIR}."
        exit 0
    fi

    for file in "${files[@]}"; do
        output_msg "Uploading ${file}..."
        
        # Execute smbclient
        # -U sets credentials, -c issues the command.
        if ! smbclient "//${NAS_HOST}/${NAS_SHARE}" -U "${NAS_USER}%${NAS_PASS}" -c "put ${file}" ; then
            output_error "Failed to upload ${file}."
            # We don't exit here so other files can still attempt to upload
        else
            output_msg "Successfully uploaded ${file}."
        fi
    done
)

output_msg "Upload process completed."
```

- [ ] **Step 2: Test empty directory behavior**

Run: `NAS_USER=user NAS_PASS=pass ./upload-isos.sh`
Expected: PASS with `No files found matching '*.iso' in ./iso-outputs.`

- [ ] **Step 3: Test wildcard finding (Mock upload)**

Run: 
```bash
touch ./iso-outputs/test1.iso ./iso-outputs/test2.iso ./iso-outputs/other.txt
# Test the loop without actually uploading by overriding smbclient in the env
NAS_USER=user NAS_PASS=pass smbclient() { echo "MOCK SMBCLIENT: put $5"; return 0; }
export -f smbclient
./upload-isos.sh
unset -f smbclient
rm ./iso-outputs/test1.iso ./iso-outputs/test2.iso ./iso-outputs/other.txt
```
Expected: PASS with mock upload outputs for `test1.iso` and `test2.iso`, ignoring `other.txt`.

- [ ] **Step 4: Commit**

```bash
git add upload-isos.sh
git commit -m "feat: implement SMB upload loop with wildcard filtering"
```
