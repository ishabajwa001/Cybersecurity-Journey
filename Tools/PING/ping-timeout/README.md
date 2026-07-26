# Ping Output Analysis Notes — Timeout Flag (`-W`)

A learning-based network observation record studying the behavior of the `-W` (timeout) flag in the Linux `ping` command under different network conditions.

---

# Table of Contents

- [Overview](#overview)
- [Methodology](#methodology)
- [Understanding the Timeout Flag](#understanding-the-timeout-flag)
- [Test Results and Analysis](#test-results-and-analysis)
  - [Test 1: Local Unreachable Host](#test-1-local-unreachable-host)
  - [Test 2: Reachable Public Host (-W 2)](#test-2-reachable-public-host--w-2)
  - [Test 3: Reachable Public Host (-W 0.5)](#test-3-reachable-public-host--w-05)
  - [Test 4: Unresponsive Remote Host](#test-4-unresponsive-remote-host)
- [Comparative Summary](#comparative-summary)
- [Key Findings](#key-findings)
- [Limitations](#limitations)
- [References](#references)
- [Conclusion](#conclusion)

---

# Overview

The `-W` flag in the Linux `ping` command specifies the maximum amount of time to wait for an ICMP Echo Reply after sending an ICMP Echo Request. If no reply is received within the specified timeout, the packet is considered lost.

Unlike the interval (`-i`), which determines how often packets are sent, the timeout only controls how long `ping` waits for a response to each packet.

This document records several experiments performed using different timeout values and network conditions to understand the practical behavior of the `-W` option.

---

# Methodology

The following experiments were performed:

1. Pinging an unreachable host on the local network.
2. Pinging a reachable public server with a timeout of **2 seconds**.
3. Pinging the same public server with a timeout of **0.5 seconds**.
4. Pinging an unresponsive remote IP address.

Each test was executed using the Linux `ping` utility on Ubuntu (WSL).

---

# Understanding the Timeout Flag

When `ping` sends an ICMP Echo Request, it waits for an ICMP Echo Reply.

The `-W` option defines the **maximum waiting time** for each reply.

### If the reply arrives before the timeout

- The reply is immediately accepted.
- The timeout has no visible effect.

### If the reply does not arrive before the timeout

- The packet is considered lost.
- `ping` proceeds according to its normal transmission interval.

Unlike the interval (`-i`), the timeout does **not** determine when the next packet is transmitted. It only specifies the maximum waiting period for a reply.

---

# Test Results and Analysis

## Test 1: Local Unreachable Host

### Command

```bash
ping -W 2 -c 4 192.168.100.250
```

### Output

```text
PING 192.168.100.250 (192.168.100.250) 56(84) bytes of data.
From 192.168.100.15 icmp_seq=3 Destination Host Unreachable

--- 192.168.100.250 ping statistics ---
4 packets transmitted, 0 received, +1 errors, 100% packet loss, time 3033ms
```

### Analysis

The destination IP address did not exist on the local network.

Before sending ICMP packets, the operating system attempted to resolve the destination MAC address using ARP. Since no device responded, the operating system generated the error:

```
Destination Host Unreachable
```

Because the failure occurred before ICMP communication could begin, the configured timeout had no visible effect.

### Observation

- Local ARP resolution failed.
- No ICMP Echo Reply was received.
- The timeout was not reached because communication failed before ICMP transmission.

---

## Test 2: Reachable Public Host (-W 2)

### Command

```bash
ping -W 2 -c 10 8.8.8.8
```

### Output Summary

```text
10 packets transmitted
10 received
0% packet loss

rtt min/avg/max/mdev =
24.451/27.862/43.884/5.514 ms
```

### Analysis

The timeout was configured as **2 seconds (2000 ms)**.

Every ICMP Echo Reply arrived within **24–44 milliseconds**, which is significantly faster than the configured timeout.

Since all replies were received before the timeout expired, the timeout setting had no visible impact on the results.

### Observation

- Successful communication.
- Stable network latency.
- No timeout events occurred.

---

## Test 3: Reachable Public Host (-W 0.5)

### Command

```bash
ping -W 0.5 -c 10 8.8.8.8
```

### Output Summary

```text
10 packets transmitted
10 received
0% packet loss

rtt min/avg/max/mdev =
24.393/26.443/33.173/2.829 ms
```

### Analysis

The timeout was reduced from **2 seconds** to **0.5 seconds (500 milliseconds)**.

Despite the shorter timeout, every reply still arrived within **24–33 milliseconds**, remaining well below the configured timeout.

This experiment also confirmed that the installed Linux `ping` implementation supports fractional timeout values.

### Observation

- Lowering the timeout produced no observable difference.
- All replies arrived long before the timeout expired.
- No packet loss occurred.

---

## Test 4: Unresponsive Remote Host

### Command

```bash
ping -W 2 -c 10 10.255.255.1
```

### Output Summary

```text
10 packets transmitted
0 received
100% packet loss

time 9217ms
```

### Analysis

The destination never responded to any ICMP Echo Requests.

Each transmitted packet exceeded the configured timeout and was treated as lost.

Although the timeout was set to **2 seconds**, the command completed in approximately **9.2 seconds**, which closely matches the default one-second transmission interval.

This demonstrates that Linux continues sending new packets at regular intervals rather than waiting for every previous packet to completely time out.

### Observation

- No ICMP replies were received.
- Every transmitted packet timed out.
- Packet transmission continued independently of reply timeouts.

---

# Comparative Summary

| Test | Destination | Timeout | Result | Observation |
|------|-------------|---------|--------|-------------|
| Test 1 | 192.168.100.250 | 2 s | Destination Host Unreachable | ARP resolution failed before ICMP communication |
| Test 2 | 8.8.8.8 | 2 s | Success | Replies arrived within 24–44 ms |
| Test 3 | 8.8.8.8 | 0.5 s | Success | Replies remained well below the configured timeout |
| Test 4 | 10.255.255.1 | 2 s | No Reply | All packets exceeded the timeout |

---

# Key Findings

- The `-W` option specifies the maximum waiting time for an ICMP Echo Reply.
- Replies arriving before the timeout are processed immediately.
- Changing the timeout does not affect healthy network connections with low latency.
- Local ARP failures generate **Destination Host Unreachable** rather than timeout events.
- Modern Linux `ping` supports fractional timeout values such as `0.5`.
- The timeout controls reply handling and does not determine the packet transmission interval.

---

# Limitations

- Tests were conducted on a single home network.
- Network latency may vary depending on Internet conditions.
- Results may differ across Linux distributions and operating systems.
- Firewalls and network policies may block ICMP traffic, affecting timeout behavior.

---

# References

- Linux `ping` Manual (`man ping`)
- RFC 792 – Internet Control Message Protocol (ICMP)
- RFC 1122 – Requirements for Internet Hosts

---

# Conclusion

The experiments demonstrate that the `-W` flag controls the maximum amount of time `ping` waits for an ICMP Echo Reply after transmitting an ICMP Echo Request.

Changing the timeout from **2 seconds** to **0.5 seconds** produced no observable difference when communicating with a responsive host because all replies were received within approximately **24–44 milliseconds**, well below either timeout value.

For unreachable local hosts, communication failed during ARP resolution, resulting in **Destination Host Unreachable** instead of timeout events. For an unresponsive remote host, every packet exceeded the configured timeout and was reported as lost.

Overall, the `-W` option is useful for controlling how long `ping` waits for replies on slow or unreliable networks without changing the normal packet transmission rate.