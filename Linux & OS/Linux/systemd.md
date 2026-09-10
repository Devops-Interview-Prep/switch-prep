# systemd — Linux Init System and Service Manager

> systemd is the init system (PID 1) and service manager for modern Linux distributions (Ubuntu, CentOS, Fedora, Debian, RHEL). It controls everything from boot to service lifecycle, logging, scheduling, and shutdown. Replaced SysVinit on most distributions since ~2014.

---

## What Is systemd?

```
systemd is PID 1 — the first process started by the kernel.
It's responsible for:
  - Booting the system (parallel service startup)
  - Managing services and daemons (start, stop, restart, monitor)
  - Mounting filesystems
  - Logging via journald
  - Device and network management integration
  - Timers (alternative to cron)
  - Socket activation (start services on-demand)

Why it replaced SysVinit:
  SysVinit: sequential startup, shell scripts, no dependency tracking
  systemd:  parallel startup (faster boot), declarative unit files,
            automatic restart, dependency management, unified logging
```

---

## Unit Types

```
Everything in systemd is a "unit" — described by unit files.

Unit Type    Extension   Description                    Example
─────────────────────────────────────────────────────────────────
service      .service    Background daemon process       nginx.service
socket       .socket     Socket that triggers a service  sshd.socket
target       .target     Group of units (like runlevel)  multi-user.target
timer        .timer      Schedule jobs (like cron)       backup.timer
mount        .mount      Mount a filesystem              home.mount
path         .path       Watch a path for changes        spool.path
slice        .slice      Resource group (cgroups)        user.slice
```

---

## Unit File Structure — nginx.service Example

```ini
[Unit]
Description=NGINX Web Server
# Start after network is up (dependency)
After=network.target
# Optional: restart if it crashes (otherwise just 'Wants')
Requires=network.target

[Service]
# How to start/stop/reload:
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -QUIT $MAINPID

# Restart policy:
Restart=always          # always restart on failure
RestartSec=5s           # wait 5s before restart attempt

# Security hardening:
User=nginx
Group=nginx
PrivateTmp=true         # isolated /tmp

# Resource limits:
LimitNOFILE=65536       # max open files

[Install]
# When: systemctl enable — which target "wants" this service?
WantedBy=multi-user.target
```

---

## Common systemctl Commands

```bash
# Service lifecycle:
systemctl start nginx          # start a service
systemctl stop nginx           # stop a service
systemctl restart nginx        # stop + start
systemctl reload nginx         # reload config without restarting (if supported)
systemctl status nginx         # show status, recent logs, PID

# Boot persistence:
systemctl enable nginx         # start on boot (creates symlink in target.wants/)
systemctl disable nginx        # don't start on boot
systemctl enable --now nginx   # enable + start immediately

# Inspect:
systemctl list-units --type=service            # all active services
systemctl list-units --type=service --all      # all services (including inactive)
systemctl list-unit-files --type=service       # enabled/disabled status

# Reload systemd after editing unit file:
systemctl daemon-reload

# Mask/unmask (prevent from ever starting):
systemctl mask nginx           # prevents starting even manually
systemctl unmask nginx         # re-allow

# Show unit file content:
systemctl cat nginx            # show unit file
systemctl show nginx           # show all properties
```

---

## Journald — Log Management

```bash
# View logs for a specific service:
journalctl -u nginx                     # all logs for nginx
journalctl -u nginx -f                  # follow (tail -f equivalent)
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2024-01-15 10:00" --until "2024-01-15 11:00"

# System-wide logs:
journalctl -b                           # logs since last boot
journalctl -b -1                        # logs from previous boot
journalctl -p err                       # error level and above
journalctl -p warning                   # warning and above
journalctl --disk-usage                 # how much disk journald uses

# Real-time:
journalctl -f                           # follow all system logs

# JSON output (for log parsing):
journalctl -u nginx -o json-pretty | head -50
```

---

## Boot Flow

```
BIOS/UEFI (firmware)
  ↓
Bootloader — GRUB2 (loads kernel)
  ↓
Linux Kernel (mounts root filesystem)
  ↓
systemd (PID 1) — reads default.target
  ↓
Runs units in dependency order (parallel where possible):
  basic.target
    → sysinit.target (mounts, hardware init)
    → network.target
    → multi-user.target (all services)
      → graphical.target (if desktop)
  ↓
Login prompt or GUI desktop

# Check boot time breakdown:
systemd-analyze                    # total boot time
systemd-analyze blame              # sorted by slowest unit
systemd-analyze critical-chain     # critical path (slowest serial chain)
```

---

## Timer Units — Alternative to Cron

```ini
# backup.timer — runs backup.service every day at 2:30 AM
[Unit]
Description=Daily Backup Timer

[Timer]
OnCalendar=*-*-* 02:30:00       # every day at 2:30 AM
Persistent=true                 # run immediately if missed (e.g., system was off)
Unit=backup.service             # service to activate

[Install]
WantedBy=timers.target
```

```bash
# Enable and start a timer:
systemctl enable --now backup.timer

# List active timers:
systemctl list-timers           # shows next trigger time

# vs crontab: systemd timers have better logging (journald), 
# dependency management, and run as a systemd unit (gets cgroup accounting)
```

---

## Daemons — Background Processes

```bash
# A daemon: background process not attached to a terminal
# Most end in 'd': sshd, httpd, nginx, systemd, journald, crond

# View running daemons:
ps aux | grep 'd$'                      # processes ending with 'd'
systemctl list-units --type=service     # all systemd-managed services

# Useful daemon facts:
# - Live independently of terminal sessions
# - Typically started at boot
# - Use SIGTERM for graceful shutdown, SIGKILL as last resort
# - Write PID files to /var/run/*.pid (systemd tracks PIDs itself)
```

---

## Unit File Locations

```
/etc/systemd/system/         System-specific units (user-created)
                             ← place custom service files here
/lib/systemd/system/         OS-provided unit files (don't edit these)
/usr/lib/systemd/system/     Package-installed unit files
~/.config/systemd/user/      User-specific units (run with --user flag)

# After editing a unit file:
systemctl daemon-reload      # re-read all unit files
systemctl restart service    # apply changes
```

---

## Interview Q&A

**Q: What is the difference between `systemctl restart` and `systemctl reload`?**
`restart` stops the service (sends SIGTERM, then SIGKILL if needed) and starts it fresh — all connections are dropped. `reload` sends SIGHUP (or the configured ExecReload command) to the running process, which re-reads its configuration without stopping — connections remain active. Example: `nginx -s reload` gracefully swaps config without dropping existing client connections. Not all services support reload; check with `systemctl status service` — if "Reload: " shows a command, reload is supported.

**Q: What does `systemctl enable` actually do?**
`enable` creates a symlink from the `WantedBy` target's `.wants/` directory to the unit file. Example: `systemctl enable nginx` creates `/etc/systemd/system/multi-user.target.wants/nginx.service → /lib/systemd/system/nginx.service`. When `multi-user.target` is reached at boot, systemd processes all units in its `.wants/` directory, which includes nginx. `enable` does NOT start the service immediately — use `enable --now` for that. `disable` removes the symlink.

**Q: How do you create a custom systemd service for a Go/Python application?**
Create a unit file at `/etc/systemd/system/myapp.service`. Minimal example:
```
[Unit]
Description=My Application
After=network.target

[Service]
ExecStart=/usr/local/bin/myapp
Restart=on-failure
User=myapp
Environment=PORT=8080

[Install]
WantedBy=multi-user.target
```
Then: `systemctl daemon-reload`, `systemctl enable --now myapp`. Use `Restart=always` for auto-restart on any exit, `Restart=on-failure` to only restart on non-zero exit. Set `User=` to a non-root user for security. Logs go to `journalctl -u myapp` automatically.
