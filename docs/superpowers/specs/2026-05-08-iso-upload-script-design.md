# ISO Upload Script Design

## Goal
Create a script (`upload-isos.sh`) to upload generated ISO files from the local build directory to a Synology NAS using SMB/CIFS.

## Context
The `gdc-baseline-iso` project generates bootable Ubuntu ISOs. These ISOs need to be transferred to a Synology NAS located at `storage.ensor-labs.com` in the `iso_share` volume. The user requested support for environment variables for credentials and the ability to filter files using wildcards.

## Architecture & Tooling
The script will use `smbclient`. 
- **Why `smbclient`?** It allows for direct file transfer using SMB protocols with username/password authentication without requiring root (`sudo`) access to mount the share locally. This makes the script safer and easier to run in automated or user environments.

## Configuration (Environment Variables)
The script will be configured via the following environment variables:

| Variable | Required | Default | Description |
| :--- | :--- | :--- | :--- |
| `NAS_HOST` | No | `storage.ensor-labs.com` | The hostname or IP of the Synology NAS. |
| `NAS_SHARE` | No | `iso_share` | The name of the SMB share on the NAS. |
| `NAS_USER` | **Yes** | None | The username for authenticating to the NAS. |
| `NAS_PASS` | **Yes** | None | The password for authenticating to the NAS. |
| `ISO_DIR` | No | `./iso-outputs` | The local directory containing the files to upload. |
| `ISO_PATTERN`| No | `*.iso` | A wildcard pattern to filter files (e.g., `edge-*.iso`). |

## Script Flow (`upload-isos.sh`)
1. **Dependency Check:** Verify that the `smbclient` command is available. If not, exit with an error instructing the user to install it (e.g., `sudo apt install smbclient`).
2. **Variable Validation:** Check if `NAS_USER` and `NAS_PASS` are set. If not, exit with an error. Set default values for `NAS_HOST`, `NAS_SHARE`, `ISO_DIR`, and `ISO_PATTERN` if they are not provided.
3. **Directory Check:** Verify that the `ISO_DIR` exists.
4. **Wildcard Expansion:** Identify all files in `ISO_DIR` that match the `ISO_PATTERN`.
5. **Upload Loop:** Loop through each matched file.
6. **Transfer:** Execute `smbclient` for each file, using the `-U` flag for credentials and the `-c` flag to issue the `put` command.
   - Example command structure: `smbclient "//${NAS_HOST}/${NAS_SHARE}" -U "${NAS_USER}%${NAS_PASS}" -c "put ${ISO_FILE}"`
7. **Error Handling:** Check the exit status of the `smbclient` command. If it fails, report the error and continue to the next file.
8. **Completion:** Report success when all files have been processed.
