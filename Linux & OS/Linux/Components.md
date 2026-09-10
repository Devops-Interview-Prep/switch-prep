# Linux OS Components

> Linux is an open-source operating system kernel. A "Linux distribution" bundles the kernel with package management, system utilities, and user-space tools into a usable OS. Understanding the component layers is essential for system administration and DevOps.

---

## Introduction

- Linux is an open-source OS kernel that interfaces between hardware and software
- Multi-user: multiple users can access system resources simultaneously
- Based on Unix — widely used in servers, embedded systems, containers, and cloud
- Linux distributions are usable operating systems built on the Linux kernel

**Common distributions:**
- Ubuntu — widely used, extensive documentation, large community support
- Fedora — cutting edge, upstream of RHEL, great for developers
- CentOS Stream — community version of RHEL, commonly used in enterprise
- Debian — stable, conservative release cycle, foundation of Ubuntu
- Arch Linux — rolling release, highly customizable, "build it yourself"

---

## Virtualization

```
Hypervisor: software that creates and runs Virtual Machines (VMs)
  - Shares hardware resources (CPU, RAM, storage) from the host
  - VMs are fully isolated from each other and the host OS
  - Each VM gets its own virtual CPU, RAM, disk, and NIC

Types:
  Type 1 (Bare Metal):    Runs directly on hardware, no host OS needed
                          e.g., VMware vSphere/ESXi, Xen, KVM (used by AWS)
  Type 2 (Hosted):        Runs on top of a host OS
                          e.g., VirtualBox, VMware Workstation

Use cases:
  - Multiple workloads on one physical server → reduces cost
  - Easy snapshots and recovery
  - Isolation between environments (dev/staging/prod)
  - Cloud computing infrastructure (AWS EC2 uses KVM/Nitro hypervisor)
```

---

## Linux Kernel

```
The kernel is the core of Linux — it runs in kernel space (ring 0).

Key responsibilities:
  - Process scheduling (which process runs on which CPU core, when)
  - Memory management (virtual memory, page tables, swap)
  - Device drivers (kernel modules for hardware)
  - System calls (user programs request kernel services via syscalls)
  - File system management (ext4, XFS, tmpfs, etc.)
  - Networking (TCP/IP stack)

Architecture: Monolithic
  - Most OS services run in kernel space for performance
  - Contrast with microkernels where services run in user space
  - Linux modules (e.g., drivers) can be loaded/unloaded dynamically

# Check kernel version:
uname -r              # e.g., 5.15.0-91-generic
uname -a              # full info

# List loaded kernel modules:
lsmod
modprobe <module>     # load a module
rmmod <module>        # remove a module
```

---

## Boot Loaders — LILO and GRUB

```
Boot sequence: BIOS/UEFI → Boot Loader → Kernel → init system

LILO (Linux Loader) — legacy:
  - One of the earliest Linux boot loaders
  - Installed in the MBR (Master Boot Record) of the hard disk
  - Not dynamic: if you change kernel, you must run 'lilo' command to reinstall
  - No longer widely used — replaced by GRUB

GRUB (GRand Unified Bootloader) — current standard:
  - Dynamic: auto-detects kernels, updates automatically
  - Supports multiple OS (multiboot)
  - GRUB2 is the modern version (used by Ubuntu, RHEL, etc.)
  - Config: /etc/grub.d/ and /etc/default/grub

# GRUB commands:
update-grub           # regenerate grub.cfg (Ubuntu/Debian)
grub2-mkconfig        # RHEL/CentOS
```

---

## Linux Component Layers

```
User Applications
      ↓ (system calls)
System Libraries (glibc, libssl, etc.)
      ↓ (kernel APIs)
Linux Kernel
      ↓ (drivers)
Hardware (CPU, RAM, Disk, Network)
```

### 1. System Libraries

Libraries that applications use to communicate with the kernel without dealing with low-level details.

```
Library      Purpose
──────────────────────────────────────────────────────────
glibc        GNU C Library — printf, malloc, open, read, write
libm         Math functions — sin(), cos(), sqrt()
libpthread   POSIX threads — multithreading support
OpenSSL      Cryptography, TLS/SSL
libcurl      HTTP client (used by AWS CLI, curl, etc.)
libxml2      XML parsing
```

### 2. System Utilities

```
Category          Commands                            Purpose
─────────────────────────────────────────────────────────────────────────
File Utilities    cp, mv, rm, find, ls, chmod, chown  Manage files
Process           ps, top, kill, nice, htop           Manage processes
Networking        ping, ifconfig, netstat, curl        Network ops
Archiving         tar, gzip, zip                      Compression
Disk              fdisk, df, mount, umount             Disk management
Package Managers  apt, yum, dnf, pacman               Install software
```

### 3. Shell

```bash
# The shell is the user interface — reads and interprets commands
# Popular shells:
#   bash  — Bourne Again Shell (most common, default on most distros)
#   zsh   — Powerful, supports plugins (Oh My Zsh)
#   sh    — Bourne Shell (POSIX compatible, scripting)
#   fish  — User-friendly with autocomplete

# Check current shell:
echo $SHELL
# Change shell:
chsh -s /bin/zsh
```

### 4. Init System / Service Manager

```bash
# The init system is the first process (PID 1) started after the kernel
# It boots all other services

# systemd (modern, most common):
systemctl start nginx        # start a service
systemctl status sshd        # check service status
systemctl enable nginx       # start on boot
journalctl -xe               # view logs

# SysVinit (legacy sequential booting — slower)
# OpenRC, runit, s6 — lightweight alternatives
```

### 5. Package Management

```bash
# DEB-based (Debian, Ubuntu):
apt update && apt install nginx
dpkg -l | grep nginx         # list installed

# RPM-based (RHEL, Fedora, CentOS):
yum install nginx
dnf upgrade

# Universal formats:
snap install code            # Snap (cross-distro)
flatpak install firefox      # Flatpak

# Arch Linux:
pacman -S nginx
```

---

## Interview Q&A

**Q: What is the difference between a kernel and a distribution?**
The Linux kernel is just the core — it manages hardware, processes, memory, and system calls. It cannot be used alone (no shell, no utilities, no package manager). A Linux distribution combines the kernel with: a package manager (apt, yum), system utilities (GNU coreutils: ls, cp, grep), an init system (systemd), a shell (bash, zsh), and often a desktop environment or server applications. Ubuntu, RHEL, and Arch Linux all use the Linux kernel but differ in their packaging choices, release cycles, and target use cases.

**Q: What is the difference between a Type 1 and Type 2 hypervisor, and what does AWS use?**
A Type 1 (bare metal) hypervisor runs directly on physical hardware without a host OS — it IS the OS. Examples: VMware ESXi, Xen, Microsoft Hyper-V. Type 2 (hosted) hypervisors run on top of a regular OS — e.g., VirtualBox, VMware Workstation. Type 1 has lower overhead and is used in data centers and cloud providers. AWS uses the Nitro hypervisor (a custom Type 1 based on KVM) for EC2 instances — it offloads most virtualization to dedicated hardware, giving near bare-metal performance.

**Q: What is the role of glibc, and what happens if it's missing or incompatible?**
`glibc` (GNU C Library) is the standard C library on Linux — it provides the system call wrappers (`open`, `read`, `write`, `malloc`), POSIX functions, and most standard C library functions. Almost every compiled program dynamically links to glibc. If you copy a binary compiled on a system with glibc 2.35 to a system with glibc 2.17, it may fail with "GLIBC_2.35 not found" — the newer function symbols don't exist. This is why Docker images are often based on the same distro/version as the build environment, and why Alpine Linux (which uses musl instead of glibc) requires programs to be compiled for musl.
