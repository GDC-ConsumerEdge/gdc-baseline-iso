# Introduction

This project automates the creation of bootable ISO images designed for flashing
bare metal machines. These ISOs provide a foundational operating system and
pre-configured partitions, laying the groundwork for the subsequent deployment
of Kubernetes nodes. They are *not* Kubernetes distributions themselves, but
rather provide the necessary base environment upon which Kubernetes nodes can be
built. These ISOs are specifically tailored for testing and development
purposes, particularly for evaluating the software environment of Google
Distributed Cloud (GDC) Connected. **This project is not intended for production
use.**

This imaging process utilizes Ubuntu cloud images and leverages cloud-init for
automated configuration. You have fine-grained control over disk partitioning.

The repository includes pre-defined templates, which can be customized to meet
specific requirements.

**Important:** These scripts have been tested with Ubuntu 20.04 and 22.04.
Compatibility with other distributions or versions is not guaranteed.

## Instructions

### Dependencies

To run the scripts provided in this repository, we recommend you use a Linux
distribution based on Debian or Ubuntu, either on your machine or in a Docker
container. The scripts will then automatically install the required
dependencies, including: `wget`, `whois`, `xorriso`, and others.

### Preparing the SSH keys

To enable passwordless SSH access to the machines, create a `pub_keys` file at
the root of this repository and copy your public SSH key(s) to it.

```bash
cat [key-file.pub] >> ./pub_keys
```

These keys will later automatically be included in the ISO images.

### Preparing the settings

The image creation process relies on Cloud Init to automate the
configuration of the target machines. This repository provides sample Cloud
Init "user-data" configuration files located in the `template-nocloud`
directory. You can use these templates as-is or create your own. The templates
are customizable by setting variables in a settings file. We provide examples of
these settings files in the `settings-*.sh` files. You can either use one of the
provided ones, or create your own.

Below is the list of available settings:

* Partitions:
  * `GRUB_PARTITION`: Size of the boot partition containing GRUB boot information
    - Default value: "1GB"
    - Contains all necessary boot loader information
  * `PRIMARY_PARTITION`: Size of the OS partition
    - Default value: "130GB"
    - Contains the OS and cluster components
    - Includes space for logs, containers, and system data
  * `AUX_PARTITION`: Size of the customer data partition
    - Default: "-1" (which means that is uses all remaining disk space)
    - Dedicated space for Software-Defined Storage (SDS) for Kubernetes volumes
    - Separates customer data from OS data
* System Configuration:
  * `KERNEL`: Kernel type selection
    - Possible values: "generic" or "hwe"
    - Default: "hwe"
    - Note: Focal Generic (5.4) doesn't support Intel AX WIFI
    - HWE provides backported kernel (5.15+) with better hardware support
  * `ETH_NAME`: Default ethernet adapter name
    - Default: "en*"
    - Supports wildcards (e.g., eth0, enp181s0f0, enp111s0)
  * `DEFAULT_USER`: System default user
    - Default: 'abm-admin' ('abm' stands for "anthos bare metal")
  * `UBUNTU_VERSION`: Base Ubuntu distribution
    - Default: "22.04.5"
* Disk configurations:
  The system supports several disk configurations, with options for both
  standard and LUKS-encrypted setups:
  * Single Disk:
    - All partitions reside on a single physical disk
    - Suitable for basic setups and testing
    - Two variants available:
      1. Standard: Use the `template-nocloud/user-data-single-disk` template
      2. LUKS-encrypted: Use the `template-nocloud/user-data-luks-single-disk` template.
         LUKS encryption provides full disk encryption for enhanced security
  * Dual Disk Configuration
    - Utilizes two physical disks
    - Offers better separation of system and data
    - First disk: Dedicated to OS (recommended to set `PRIMARY_PARTITION="-1"`)
    - Second disk: Dedicated to customer data (`AUX_PARTITION`)
    - Two variants available:
      1. Standard: Uses `template-nocloud/user-data-dual-disk` template
      2. LUKS-encrypted: Uses `template-nocloud/user-data-luks-dual-disk` template.
         LUKS encryption can be applied to both disks for comprehensive security

### Creating the ISOs

One you've selected and customized your user-data template and settings files,
you can create the ISOs by running the `generate-isos.sh` script, for example:

```shell
HOSTNAME_PREFIX="edge"
NODE_COUNT="3"
TEMPLATE="template-nocloud/user-data-single-disk"
SETTINGS="settings-single-disk-nuc.sh" 

./generate-isos.sh -n ${NODE_COUNT} -t ${TEMPLATE} -s ${SETTINGS} -k . -h ${HOSTNAME_PREFIX} -o ./iso-outputs
```

Once generated, the ISOs can be found in the `iso-outputs` directory.

To get a list of available options for the script, run this command:

```shell
./generate-isos.sh -?
```

## Flashing a USB drive

After generating your ISOs, the next step is to create a bootable USB drive that
can be used to install the images on bare metal machines. These ISOs are stored
in the `iso-outputs` directory.

You can create the bootable USB drive using one of the following methods.

### Using Graphical Tools (Windows/MacOS)

* For Windows users: [Rufus](https://rufus.ie/) - A reliable and user-friendly USB flashing tool
* For MacOS users: [balena Etcher](https://www.balena.io/etcher/) - Simple graphical interface for flashing ISOs

If you use Etcher, follow these steps:
1. Click "Flash from File"
2. Select an ISO file from the `./iso-outputs` directory
3. Click "Select Target"
4. Select your USB drive
5. Click "Flash"

### Using Command Line (Linux/MacOS)

You can use the `dd` command-line tool:

```shell
# First, list available drives to identify your USB device
lsblk

# Then flash the ISO (replace /dev/sdX with your USB drive)
# OF = output file (target USB device - this will be overwritten)
# IF = input file (the ISO you want to flash)
sudo dd if=./iso-outputs/edge-1.iso of=/dev/sdX status=progress
```

## Flashing the machines

After flashing the USB drive with the ISO, you're ready to flash your machine.

> ⚠️ WARNING: These ISOs are designed for automated installation. When booting
> from the USB drive, it will automatically wipe and partition the target
> computer's disk without any prompts or confirmation!

When installation completes, the system will automatically reboot. Be sure to
remove the USB drive after installation to prevent the system from booting back
into the installer.

## Next steps

Once you've flashed all your machines, you are ready to set up the Kubernetes
cluster. Follow the instructions at: https://github.com/gdc-consumeredge/consumer-edge-core
