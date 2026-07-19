# Using Putty terminal
- Its a free and open source terminal
- widely used for remote access to server via using ssh

- **Connect to CentOS**
  - Allow server to do ssh from your ip and connect on port 22
  - `ifconfig` to check ip of the server
  - reboot
- **Connect to UBUNTU**
  - To check ip `ip addr`
  - to allow ssh install openssh server `sudo apt install openssh-server`
  - then `systemctl start ssh`

# Using normal terminal

- `ssh username@server-ip -p port`
- later will ask for the password 

# File Transfer bw Linux and Windows(WinScp)

- install WinScp on windows 
- connect to linux server
- will give you gui then do the drag and drop

# File Transfer bw two linux servers (scp)

- cli tool to securly transfer files between a local and a remote or between two remote hosts using ssh for encryption and authentication
- `scp /local/file username@host-server:/path/`
- use -r for directory
- use * for all files

# Login without using a password

- Copy public key of local machine to server's `~/.ssh/authorizedkeys`
- if you dont have ssh key create using ssh-keygen
- To copy use `ssh-copy-id user@server-ip` 

---

## SSH Key Management

```bash
# Generate SSH key pair (Ed25519 is modern + secure)
ssh-keygen -t ed25519 -C "pawan@company.com" -f ~/.ssh/id_ed25519

# Or RSA 4096 for broader compatibility
ssh-keygen -t rsa -b 4096 -C "pawan@company.com"

# Copy public key to remote server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server-ip

# Manual copy (if ssh-copy-id unavailable)
cat ~/.ssh/id_ed25519.pub | ssh user@server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Verify key-based login
ssh -i ~/.ssh/id_ed25519 user@server-ip
```

## SSH Config File (~/.ssh/config)

Avoid typing long SSH commands:

```
# ~/.ssh/config
Host prod-bastion
    HostName 54.123.45.67
    User ec2-user
    IdentityFile ~/.ssh/id_ed25519
    Port 22

Host dev-server
    HostName 10.0.1.50
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    ProxyJump prod-bastion    # SSH through bastion host!

Host *
    ServerAliveInterval 60   # keep connections alive
    ServerAliveCountMax 3
```

```bash
# Now connect simply:
ssh prod-bastion
ssh dev-server   # automatically jumps through bastion
```

## SSH Tunneling / Port Forwarding

```bash
# Local port forwarding: access remote service via local port
# Access remote DB (port 5432) via localhost:5432
ssh -L 5432:db.internal:5432 user@bastion

# Remote port forwarding: expose local service on remote port
ssh -R 8080:localhost:8080 user@server

# SOCKS proxy: route all traffic through SSH tunnel
ssh -D 1080 user@server   # configure browser/tool to use SOCKS5 at localhost:1080

# Non-interactive tunnel (background daemon)
ssh -N -f -L 5432:db.internal:5432 user@bastion
```

## SSH Security Hardening (/etc/ssh/sshd_config)

```bash
# Key settings to harden SSH:
PermitRootLogin no                  # never allow root SSH
PasswordAuthentication no           # keys only, no passwords
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
Port 2222                           # non-standard port (minor security)
AllowUsers deployer admin          # whitelist specific users
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# Reload after changes
systemctl reload sshd
```

## Common Interview Questions

**Q: What is SSH agent forwarding and when should you use it?**
Agent forwarding (`ssh -A`) forwards your local SSH agent to the remote server, so you can SSH from the remote server to another server using your local keys — without copying your private key to the intermediate host. Use case: bastion host → internal servers. Risk: anyone with root on the bastion can use your forwarded agent. Prefer `ProxyJump` (direct tunnel) over agent forwarding — it's more secure as your keys never leave your local machine.

**Q: How does public key authentication work?**
At setup: your public key is placed in the server's `~/.ssh/authorized_keys`. At login: server generates a random challenge, encrypts it with your public key, sends to client. Client decrypts with private key and sends back proof. Server verifies — no password transmitted. This is why losing your private key is serious, and why SSH keys should have passphrases.


