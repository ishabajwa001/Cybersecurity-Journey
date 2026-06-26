# ping Manual

ping checks if a host (website or IP) is reachable over the network and measures how long it takes to get a response.

---

## How it works

You send a small packet to a destination. If the host is alive, it sends one back. ping measures the round-trip time (RTT) in milliseconds.

```bash
ping google.com
ping 8.8.8.8
```

---

## Basic Syntax

```bash
ping [options] <destination>
```

---

## Common Commands You'll Actually Use

```bash
# Send only 4 packets then stop
ping -c 4 google.com

# Send a packet every 0.5 seconds instead of 1
ping -i 0.5 google.com

# Stop after 10 seconds no matter what
ping -w 10 google.com

# Only show the final summary, not every packet
ping -q -c 10 google.com

# Force IPv4
ping -4 google.com

# Force IPv6
ping -6 google.com

# Use a specific network interface
ping -I eth0 google.com

# Larger packet size (useful for testing)
ping -s 1024 google.com
```

---

## All Options

### Control how many packets are sent

| Option | What it does |
|--------|-------------|
| `-c <number>` | Stop after sending this many packets. Example: `-c 5` sends 5 then exits |
| `-w <seconds>` | Stop after this many seconds no matter what |
| `-W <seconds>` | How long to wait for a reply before giving up. `0` means wait forever |
| `-l <number>` | Send this many packets at once before waiting for replies (needs root for >3) |

### Control the timing

| Option | What it does |
|--------|-------------|
| `-i <seconds>` | Gap between packets. Default is 1 second. Below 0.002s needs root |
| `-A` | Auto-adjust the gap based on how fast replies come back |
| `-f` | Flood mode — sends as fast as possible. **Root only. Don't use on real networks** |

### Control what you see

| Option | What it does |
|--------|-------------|
| `-q` | Quiet — only shows the summary at the end |
| `-v` | Verbose — shows more detail |
| `-D` | Show a timestamp before each line |
| `-n` | Skip DNS lookups, show raw IP addresses only (faster) |
| `-H` | Force hostname resolution even in numeric/flood mode |
| `-O` | Show if a packet went unanswered before sending the next |
| `-U` | Show full user-to-user time instead of just network time |
| `-3` | More precise RTT values (no rounding) |
| `-a` | Make a beep sound when a reply comes in |

### Control the packet itself

| Option | What it does |
|--------|-------------|
| `-s <bytes>` | Size of the data in each packet. Default is 56 bytes |
| `-t <number>` | Set TTL (how many routers the packet can pass through before being dropped) |
| `-p <hex>` | Fill the packet with a pattern, e.g. `-p ff` fills with all 1s |
| `-Q <value>` | Set Quality of Service bits |
| `-e <id>` | Manually set the ICMP ID field |

### Control routing and interface

| Option | What it does |
|--------|-------------|
| `-I <name or IP>` | Send from a specific network interface or IP address |
| `-4` | Use IPv4 only |
| `-6` | Use IPv6 only |
| `-r` | Skip the routing table and send directly to a connected host |
| `-B` | Lock the source address so ping can't change it |
| `-b` | Allow pinging a broadcast address |
| `-L` | Don't loop back multicast packets |
| `-m <mark>` | Tag packets for policy-based routing (needs admin rights) |

### Path MTU Discovery

Controls how ping handles packet size limits across the network.

| Option | What it does |
|--------|-------------|
| `-M do` | Set DF flag — reject packets that are too large |
| `-M want` | Try to discover MTU, fragment locally if needed |
| `-M probe` | Set DF flag but skip size checks (for testing) |
| `-M dont` | Don't set the DF flag at all |

### Timestamps

| Option | What it does |
|--------|-------------|
| `-T tsonly` | Include timestamps only |
| `-T tsandaddr` | Include timestamps + addresses |
| `-T tsprespec h1 h2` | Timestamp at specific hops |

### Record route

| Option | What it does |
|--------|-------------|
| `-R` | Try to record the hops the packet takes (max 9). Most routers ignore this |

### Other

| Option | What it does |
|--------|-------------|
| `-F <label>` | IPv6 only. Set a flow label (0 = kernel picks one) |
| `-V` | Show version and exit |
| `-h` | Show help |
| `-C` | Call connect() when creating the socket |
| `-d` | Set SO_DEBUG on socket (almost never needed) |

---

## Reading the Output

```
PING google.com (142.250.180.46): 56 data bytes
64 bytes from 142.250.180.46: icmp_seq=1 ttl=116 time=12.3 ms
64 bytes from 142.250.180.46: icmp_seq=2 ttl=116 time=11.9 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
rtt min/avg/max/mdev = 11.8/12.1/12.5/0.3 ms
```

| Field | Meaning |
|-------|---------|
| `icmp_seq` | Packet number. Gaps mean dropped packets |
| `ttl` | Hops remaining when the reply arrived |
| `time` | Round-trip time in milliseconds. Lower is better |
| `min` | Fastest reply you got |
| `avg` | Average reply time |
| `max` | Slowest reply you got |
| `mdev` | How much the time varies. High = unstable connection |

---

## ICMP Packet Details

When you run ping, here is what actually gets sent:

- **IP header** — 20 bytes (routing info, source/destination IP)
- **ICMP header** — 8 bytes (type, code, checksum, ID, sequence)
- **Data** — 56 bytes by default (changeable with `-s`)

So the total default packet size is **20 + 8 + 56 = 84 bytes**.

The reply you get back will always have **8 more bytes** than the data you sent, because of the ICMP header. ping uses the first few bytes of the data section to store a timestamp, which it uses to calculate the round-trip time.

> If you set `-s` to a very small value (smaller than a timestamp), ping won't be able to calculate RTT and won't show `time=` in output.

---

## TTL Explained

**TTL (Time To Live)** is a counter on every packet. Every router it passes through reduces TTL by 1. When TTL hits 0, the packet is thrown away.

- Default max TTL is **255**, recommended starting value is **64**
- Helps prevent packets from looping forever on the internet

When a remote host replies to your ping, it can handle TTL in three ways:

| Behaviour | What you see | Who does this |
|-----------|-------------|---------------|
| Doesn't change TTL | `255 - number of routers in full round trip` | Old BSD systems |
| Sets TTL to 255 | `255 - number of routers from remote to you` | Modern BSD/Linux |
| Sets TTL to something else | Any value, e.g. 30, 60, or random | Some custom systems |

---

## Duplicate and Damaged Packets

ping will warn you if it receives unusual packets:

**Duplicate packets**
- Should never happen in normal conditions
- Usually caused by the network retransmitting packets at a low level
- A few duplicates may not be alarming, but many duplicates is a problem

**Damaged packets**
- This is always a serious warning
- Usually means broken hardware somewhere on the network path — a bad cable, faulty router, or broken NIC

---

## ID Collisions

Every ping process uses an ID number to match the replies it gets back to the packets it sent. This ID is a 16-bit number (max value: 65535).

ping uses its **process ID (PID)** as its ID. The problem:

- If two ping processes run at the same time with the same PID (or PID > 65535), they can steal each other's replies
- The default Linux `pid_max` is 32768, so on busy systems with many ping processes, collisions can happen
- When this occurs, ping prints `DIFFERENT ADDRESS` error and packet loss may show as negative

---

## Trying Different Data Patterns

Sometimes a network drops packets only for certain data patterns (e.g. all zeros or all ones). This is called a **data-dependent problem**.

You can test for this using `-p`:

```bash
# Fill packet with all 1s
ping -p ff google.com

# Fill packet with all 0s
ping -p 00 google.com

# Custom pattern
ping -p deadbeef google.com
```

> If you notice some files transfer fine but others don't, check the file for repeating byte patterns — those are good candidates to test with `-p`.

---

## IPv6 Node Information Queries (`-N`)

Only for IPv6. Instead of sending an Echo Request, this sends a Node Information Query to ask the host about itself. Requires root (`CAP_NET_RAW`).

| Sub-option | What it asks |
|------------|-------------|
| `help` | Show help for NI support |
| `name` | What is the node's name? |
| `ipv6` | What IPv6 addresses does it have? |
| `ipv6-global` | Global-scope IPv6 addresses |
| `ipv6-sitelocal` | Site-local IPv6 addresses |
| `ipv6-linklocal` | Link-local IPv6 addresses |
| `ipv6-all` | IPv6 addresses on all its interfaces |
| `ipv4` | What IPv4 addresses does it have? |
| `ipv4-all` | IPv4 addresses on all its interfaces |
| `subject-ipv6=<addr>` | Set the IPv6 address to query about |
| `subject-ipv4=<addr>` | Set the IPv4 address to query about |
| `subject-name=<name>` | Query by hostname |
| `subject-fqdn=<name>` | Query by fully-qualified domain name |

---

## IPv6 Link-Local Addresses

When pinging a link-local IPv6 address you must specify the interface, because link-local addresses are not globally unique — they only make sense within one network segment.

```bash
# Using % after the address
ping fe80::5054:ff:fe70:67bc%eth0

# Using -I flag
ping -I eth0 fe80::5054:ff:fe70:67bc
```

---

## Exit Codes

Useful when using ping inside shell scripts.

| Code | Meaning |
|------|---------|
| `0` | Host replied — it's reachable |
| `1` | No reply received, or deadline passed before count was reached |
| `2` | An error occurred |

```bash
# Example: check if host is up
ping -c 1 google.com && echo "Host is up" || echo "Host is down"
```

---

## Environment Variable

| Variable | What it does |
|----------|-------------|
| `IPUTILS_PING_PTR_LOOKUP=0` | Turns off reverse DNS lookups globally. Can be overridden with `-H` or `-n` |

---

## Security

ping needs `CAP_NET_RAW` (elevated privileges) in these cases:

- Using `-N` (node info queries)
- Using `-e 0` (raw socket mode)
- Kernel doesn't support ICMP datagram sockets
- Your user isn't allowed to create ICMP echo sockets

On some systems ping runs as **set-uid root**, which gives it the permissions it needs automatically.

---

## Known Bugs

- Many routers and hosts **ignore the `-R` (record route) option** entirely
- The IP header is too small to store more than 9 route hops, making `-R` limited even when it works
- **Flood pinging a broadcast address** should only be done in very controlled test environments — it can flood an entire network

---

## History

- `ping` first appeared in **4.3BSD**
- The Linux version is a descendant of that original
- As of version **s20150815**, `ping6` no longer exists as a separate binary — it was merged into `ping`. You can create a symlink `ping6 -> ping` to get the old behaviour back

---

## See Also

- `ip(8)` — network interface and routing configuration
- `ss(8)` — socket statistics

---

*ping is part of the **iputils** package (version 20250605)*