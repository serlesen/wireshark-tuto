# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the W4SP Lab (Wireshark for Security Professionals Lab) - a Docker-based network security lab environment for learning Wireshark and network security fundamentals. The lab creates realistic network topologies with multiple Docker containers functioning as routers, switches, victims, and various services, all orchestrated through a Flask web interface.

Based on the w4sp-book/w4sp-lab project with custom fixes and improvements.

## Running the Lab

**Primary entry point:**
```bash
sudo python3 w4sp_webapp.py
```

This starts the Flask web server on port 5000 and automatically opens Firefox to http://127.0.0.1:5000. The script must run as root because it manipulates network namespaces.

**Build Docker images:**
```bash
# Build all lab images (happens automatically on first run)
cd images/
docker build -t w4sp/labs:base base/
docker build -t w4sp/labs:<image_name> <image_name>/
```

**Standalone Docker container:**
```bash
docker build -t wireshark-tuto .
docker run -it wireshark-tuto /bin/bash
```

## Architecture

### Three-Layer Architecture

1. **Flask Web Application** (`w4sp_webapp.py`)
   - Provides REST API endpoints for lab control
   - Routes: `/setup`, `/shutdown`, `/runshark`, `/getnet`, `/wifi`, `/ips`, `/elk`, etc.
   - Launches Wireshark instances in specific network namespaces
   - Renders network topology visualization using vis.js

2. **Core Lab Logic** (`w4sp.py` and `w4sp_app/`)
   - `container.py`: Core abstraction for Docker containers and network namespaces
   - `lab_helper.py`: High-level network setup functions
   - `utils.py`: System utilities and Docker management

3. **Docker Images** (`images/`)
   - Each subdirectory represents a different node type (router, switch, victim, etc.)
   - All images inherit from `w4sp/labs:base` (Ubuntu 14.04)
   - Images are labeled with `w4sp=true` for easy cleanup

### Network Namespace Management

The core abstraction is in `w4sp_app/container.py`:

- **`root_ns` class**: Represents the host's root network namespace (PID 1)
  - Manages global list of all container namespaces
  - Methods: `enter_ns()`, `exit_ns()`, `connect()`, `register_ns()`, `shutdown()`

- **`container` class**: Represents a Docker container with its own network namespace
  - Inherits from `root_ns`
  - Creates containers with `--net=none` for full network control
  - Links `/proc/<pid>/ns/net` to `/var/run/netns/<name>` for `ip netns` command compatibility
  - Methods: `dexec()` for running commands in container, plus all inherited methods

- **`c()` function**: Convenience function to retrieve container object by name

### Network Topology Creation

Networks are defined as nested dictionaries in `w4sp.py`:

```python
net_1 = {
    'subnet': '192.100.200.0/24',
    'hubs': [{
        'switch': ['sw1'],
        'clients': [
            {'vrrpd': ['r1', 'r2']},
            {'victims': ['vic1', 'vic2', 'vic3']},
            {'samba': ['smb1']},
            {'ftp_tel': ['ftp1']}
        ]
    }]
}
```

**Network setup functions** (`w4sp_app/lab_helper.py`):
- `create_net()`: Creates containers, sets up switch bridges, assigns IPs, configures DHCP/DNS
- `setup_sw()`: Configures a switch node with bridge interface and dnsmasq DHCP server
- `setup_vrrp()`: Configures VRRP (Virtual Router Redundancy Protocol) on routers
- `setup_inet()`: Configures NAT for internet connectivity

### VETH Pair Connections

Network connections use VETH (Virtual Ethernet) pairs:
- Created with `ip link add <name> type veth peer name tmp`
- One end moved to target namespace with `ip link set <nic> netns <pid>`
- Checksum offloading disabled to prevent packet corruption
- NICs named as `<container>_<number>` (e.g., `sw1_0`, `sw1_1`)

### Key Design Patterns

1. **Namespace Context Management**: Code frequently enters/exits namespaces using:
   ```python
   container.enter_ns()
   # ... execute commands in container's namespace
   container.exit_ns()
   ```

2. **String Interpolation with `r()` function**: Executes shell commands with bash-like variable expansion:
   ```python
   r('ip link set $nic up')  # $nic replaced from caller's locals()
   ```

3. **Docker Labels**: All containers tagged with `w4sp=true` for bulk operations

4. **Supervisor for Process Management**: All containers use supervisord to manage services

## Docker Image Types

- **base**: Ubuntu 14.04 with common tools (bridge-utils, ethtool, nmap, mtr, iptables)
- **switch**: Acts as L2 switch with Linux bridge and runs dnsmasq for DHCP/DNS
- **vrrpd**: Router with VRRP daemon for redundancy
- **inet**: Internet gateway with NAT capabilities
- **victims**: Target machines for security exercises
- **ftp_tel**: FTP and Telnet services (supports SSL/TLS)
- **samba**: SMB/CIFS file sharing
- **wireless**: Wireless access point using hostapd (cleartext and WPA2)
- **elk**: ELK stack for log analysis
- **sploitable**: Intentionally vulnerable machine

## Common Issues & Fixes

1. **Network namespace cleanup**: Always use `docker_clean()` from `w4sp_app/utils.py` which:
   - Removes all containers with label `w4sp=true`
   - Deletes VETH interfaces
   - Removes network namespaces
   - Kills dhclient processes
   - Restarts network-manager and docker

2. **Wireshark permissions**: The `check_dumpcap()` function sets correct capabilities:
   ```bash
   setcap CAP_NET_RAW+eip CAP_NET_ADMIN+eip $(which dumpcap)
   ```

3. **User setup**: Must run as `w4sp-lab` user (created automatically) with sudo, password: `w4spbook`

4. **Docker iptables**: The lab disables iptables filtering and sets all chains to ACCEPT to prevent interference

## Development Guidelines

- **Modifying network topology**: Edit the `net_1`, `net_2` dictionaries in `w4sp.py` or `w4sp_webapp.py:/setup` route
- **Adding new image types**: Create new directory in `images/`, inherit from base, add supervisor configs
- **Testing individual components**: Use Python REPL with `from w4sp_app import *` for interactive testing
- **Debugging namespace issues**: Check `/proc/<pid>/ns/` and `/var/run/netns/` for namespace links

## Important Notes

- This lab requires root privileges for network namespace manipulation
- Designed for Kali Linux but works on other Debian-based distributions
- The lab manipulates host networking extensively - always run in a VM or dedicated environment
- Default credentials throughout: username `w4sp`, password `w4spbook`
- All containers are ephemeral - destroyed on cleanup