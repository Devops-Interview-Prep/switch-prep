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

