# Lab 4 — Installation of Linux

## Objectives

- Install Ubuntu on VMware Workstation / VMware Fusion
- Perform first-boot configuration (user, hostname, updates)
- Understand the Linux filesystem layout
- Run a post-install verification script

## Background

**Ubuntu** is a Debian-based Linux distribution widely used in cloud and DevOps environments.
In this lab you install it inside a **VMware** virtual machine so that the host OS is unaffected.

Key concepts:
- A **VM** (virtual machine) shares hardware with the host but runs an isolated OS
- Ubuntu ships as an **ISO image** — a virtual DVD you mount in VMware
- The installer partitions a virtual disk, writes the OS, and sets up a bootloader (GRUB)

## Part 1 — Create the VM in VMware

1. Open **VMware Workstation** (Windows/Linux) or **VMware Fusion** (macOS)
2. Click **Create a New Virtual Machine → Typical**
3. Choose **Installer disc image file (ISO)** and browse to your Ubuntu `.iso`
4. Set:
   - Guest OS: **Linux → Ubuntu 64-bit**
   - VM name: `ubuntu-lab`
   - Disk size: **20 GB** (store as a single file)
   - Memory: **2048 MB** (2 GB minimum)
5. Click **Finish** — VMware powers the VM on automatically

## Part 2 — Install Ubuntu

1. At the GRUB menu select **Try or Install Ubuntu**
2. Choose language → **Install Ubuntu**
3. Keyboard layout → **Continue**
4. Updates and other software → **Normal installation**, tick **Install third-party software**
5. Installation type → **Erase disk and install Ubuntu** (safe — only affects the virtual disk)
6. Set timezone → **Continue**
7. Create your user account:
   - Your name: `Lab User`
   - Computer name: `ubuntu-lab`
   - Username: `labuser`
   - Password: choose one and confirm
8. Click **Install Now** → wait (~10 minutes) → **Restart Now**
9. Press **Enter** when prompted to remove the installation medium

## Part 3 — First-Boot Configuration

Open a terminal (`Ctrl+Alt+T`) and run the post-install script from this lab:

```bash
bash scripts/01-post-install-config.sh
```

Or step through manually:

```bash
# 1. Update package lists and upgrade installed packages
sudo apt update && sudo apt upgrade -y

# 2. Set the hostname
sudo hostnamectl set-hostname ubuntu-lab

# 3. Check current user and groups
whoami
groups

# 4. Explore the filesystem layout
ls /
```

## Part 4 — Filesystem Layout

| Directory | Purpose |
|-----------|---------|
| `/`       | Root of the entire filesystem |
| `/home`   | User home directories |
| `/etc`    | System-wide configuration files |
| `/var`    | Logs, caches, spool files |
| `/usr`    | Installed programs and libraries |
| `/tmp`    | Temporary files (cleared on reboot) |
| `/boot`   | Kernel and bootloader files |
| `/dev`    | Device files (disks, terminals) |
| `/proc`   | Virtual FS exposing kernel/process info |

## Scripts

```bash
cd lab-04-linux-installation/

# Post-install configuration and verification
bash scripts/01-post-install-config.sh
```

## VMware Tips

- **Take a snapshot** right after install — lets you roll back if something breaks
- **VMware Tools**: Ubuntu usually installs `open-vm-tools` automatically; if not: `sudo apt install open-vm-tools-desktop`
- Shared clipboard and drag-and-drop require VMware Tools to be running
