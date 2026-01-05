# What is systemd in Linux?
- systemd is the init system and service manager used by most modern Linux distributions (e.g. Ubuntu, CentOS, Fedora, Debian).

- It is the first process that starts when your Linux system boots (it has PID 1), and it is responsible for:

  - Booting the system
  - Managing services and daemons
  - Handling system shutdown and restarts
  - Mounting filesystems
  - Logging (via journald)
  - Device and network management integration

# Why was systemd introduced?

- Before systemd, systems used SysVinit
- systemd was introduced to:
    - To Speed up boot time (parallel service startup)
    - Standardize service behavior
    - Offer better process control and logging


# Key Features of systemd
```
Feature	                    Description
Unit files	                Declarative configuration files for services, sockets, targets, etc.
Parallel startup	        Starts multiple services simultaneously during boot
Socket activation	        Starts services only when their socket receives traffic (saves resources)
journald logging	        Built-in system log manager
Service monitoring	        Automatically restarts crashed services
Target-based boot	        Like runlevels in SysVinit (e.g., multi-user.target, graphical.target)
```


# Common Unit Types

```
Unit Type	                     Description	                         File Example
service	                A daemon or background process	                 nginx.service
socket	              A socket that can trigger a service                cups.socket
target	                A group of units (like runlevels)	             multi-user.target
mount	                      Mount a filesystem	                     home.mount
timer	                    Schedule a job (like cron)	                 backup.timer
```

# Common systemctl Commands

```
Command	Description
systemctl status nginx	View status of a service
systemctl start nginx	Start a service
systemctl stop nginx	Stop a service
systemctl restart nginx	Restart a service
systemctl enable nginx	Start service on boot
systemctl disable nginx	Don't start on boot
systemctl list-units --type=service	Show all running services
journalctl -u nginx	Show logs for nginx
```

# systemd Boot Flow (Simplified)

`BIOS/UEFI → Bootloader (GRUB) → Linux Kernel → init (systemd) → system units → user login `

# Location of unit files

```
Location	Purpose
/etc/systemd/system/	System-specific (user-created) units
/lib/systemd/system/	OS-provided unit files
~/.config/systemd/user/	User-specific units
```

# Example: Simple nginx.service Unit File

```
[Unit]
Description=NGINX Web Server
After=network.target

[Service]
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -QUIT $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
```

# Daemon
- A daemon (pronounced DEE-muhn) is a background process in Linux or Unix-like systems that runs without direct user interaction.
- Runs in the background, not attached to a terminal
- Doesn't interact directly with the user
- Usually starts at boot and stays running to provide a service
- Many daemons end in d (e.g., sshd, httpd, systemd)
- Modern systems start and monitor daemons using the systemd init system
- Lives independently of terminal

```
ps aux | grep 'd$'       # See processes ending with 'd'
systemctl list-units --type=service  # List active systemd services
```
