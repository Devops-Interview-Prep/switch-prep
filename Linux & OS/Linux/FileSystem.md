#  Linux File System Hierarchy
1. `/`           -    root dir.
2. `/bin`        -    Essential user binaries (commands) needed for system operation, like ls, cp, mv, cat.
3. `/sbin`       - 	  Essential system binaries used for system administration, like reboot, fsck, ip.
4. `/etc`        -    Configuration files for the system and applications. E.g., /etc/ssh/sshd_config, /etc/passwd.
5. `/home`       -    User directories
6. `/var`        -    Variable files — logs, mail, spool files, temporary files that grow over time (e.g., /var/log)
7. `/tmp`        -    Temporary files,Cleared on reboot
8. `/usr`        -    Contains secondary system utilities and applications. Think of it as a “user space” for installed software.
9. `/proc`       -    Virtual filesystem containing system information (e.g., /proc/cpuinfo, /proc/meminfo)
10. `/dev`       -    Device files for accessing hardware (e.g., /dev/sda, /dev/tty). Everything is treated as a file in Linux
11. `/root`      -    Home directory for the root user (not to be confused with /).
12. `/lib`       -    Essential shared libraries required by binaries in /bin and /sbin.
13. `/usr/bin`   -    Non-essential user binaries (e.g., python, vim, gcc).
14. `/usr/sbin`	 -    Non-essential system binaries used by admins.
15. `/usr/lib`   -    Libraries for programs in /usr/bin and /usr/sbin.
16. `/sys`       -    Interface to the kernel for hardware information (like /sys/class/net/eth0).
17. `/boot`      -    Files needed to boot the system, including the kernel and GRUB bootloader.
18. `/media`     -    Mount point for removable media (USB, CD/DVD).
19. `/mnt`	     -    Temporary mount point for manual mounts.
20. `/opt`       -    Optional or third-party software packages (e.g., /opt/google).
21. `/srv`	     -    Data for services like web and FTP servers (e.g., /srv/www, /srv/ftp).
22. `/run`	     -    Runtime data since boot (e.g., process IDs, sockets). Cleared on reboot.
23. `/snap`	     -    Used by Snap packages (from Canonical), an app packaging system.



**/etc**

- Acts as the “brain” of the system — almost all system-wide config files are here.

- Examples:
    - /etc/fstab – file system mount points.
    - /etc/network/interfaces – legacy network config.
    - /etc/systemd/ – systemd unit files.

**/proc and /sys**

- These are virtual filesystems.

- /proc exposes kernel and process information (e.g., ps uses /proc).

- /sys provides info about hardware devices and their drivers.

**/dev**

- Every device is represented as a file.

- /dev/sda – first hard disk.

- /dev/null – black hole device (discard output).

- /dev/tty – terminal devices.

**Filesystem Mounting and Devices**

- Mount points link physical or virtual storage devices to the file tree.

- You might mount:

    - A USB drive to /media/usb
    - A new disk to /mnt/data
