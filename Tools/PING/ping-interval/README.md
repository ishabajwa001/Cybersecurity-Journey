# Ping Output Analysis Notes — Interval Flag (`-i`)
A learning-based network observation record studying the behavior of the `-i` flag in the `ping` command across different target types.

---

## Overview

This directory contains raw output logs from `ping` run against different targets using the `-i` (interval) flag, which sets the delay in seconds between successive ICMP packets. The goal is to observe how interval length affects test duration and sample density, with and without `-c` (count).

```bash
ping -i <interval_seconds> [-c <count>] <target>
```

When `-c` is omitted, ping runs until manually stopped with `Ctrl+C` (`^C`) — this still triggers the normal summary statistics.

---

## Test Results and Analysis

### `github.com` — interval 2s, manually stopped

| Property | Result |
|----------|--------|
| Packets Sent | 34 (Ctrl+C) |
| Avg Latency | ~62.2 ms |
| Packet Loss | 0% |
| Total Time | ~69.15 s |

Consistent latency (mdev: 8.0 ms) with minor spikes, suggesting brief transient congestion rather than a real issue.

### `localhost` — interval 0.5s, manually stopped

| Property | Result |
|----------|--------|
| Packets Sent | 16 (Ctrl+C) |
| Avg Latency | ~0.092 ms |
| Packet Loss | 0% |
| Total Time | ~7.70 s |

Negligible, stable latency as expected for loopback traffic. The first packet's small spike (0.694 ms) is typical warm-up, not a real trend.

### `mozilla.org` — interval 5s, count 5

| Property | Result |
|----------|--------|
| Packets Sent | 5 |
| Resolved IP | 35.190.14.201 (Google Cloud-hosted) |
| Avg Latency | ~27.6 ms |
| Packet Loss | 0% |
| Total Time | ~20.02 s |

Very consistent latency (mdev: 1.15 ms). The `googleusercontent.com` reverse DNS confirms mozilla.org is served from Google Cloud rather than a Mozilla-owned IP.

### `208.67.222.222` — interval 1.5s, count 20

| Property | Result |
|----------|--------|
| Packets Sent | 20 |
| Avg Latency | ~28.5 ms |
| Packet Loss | 0% |
| Total Time | ~28.54 s |

Slightly more jitter (mdev: 4.65 ms) than other tests, but no packet loss. Total time closely matches the expected `interval × (count - 1)`.

**Why this IP?** `208.67.222.222` is one of **OpenDNS's** public DNS resolver addresses (operated by Cisco). It's a common ping target in networking exercises because it's well-known, stable, and always-on — a reliable stand-in for "some external host" when testing raw connectivity, as opposed to testing a specific website like github.com or mozilla.org.

---

## Comparative Summary

| Target | Interval | Count | Total Time | Avg Latency | Loss |
|--------|----------|-------|------------|--------------|------|
| `github.com` | 2s | 34 (manual) | ~69.15 s | ~62.2 ms | 0% |
| `localhost` | 0.5s | 16 (manual) | ~7.70 s | ~0.092 ms | 0% |
| `mozilla.org` | 5s | 5 | ~20.02 s | ~27.6 ms | 0% |
| `208.67.222.222` (OpenDNS) | 1.5s | 20 | ~28.54 s | ~28.5 ms | 0% |

---

## Key Findings

- `-i` sets the delay between packets, not the count — total runtime ≈ `interval × (packets sent - 1)`
- `-i` + `-c` together give a predictable, bounded test duration
- Without `-c`, ping runs until Ctrl+C, printing the same summary format as a normal exit
- Shorter intervals (e.g. 0.5s) capture jitter better on low-latency paths like loopback
- Longer intervals (e.g. 5s) are lighter on the network but take longer for the same sample count
- All intervals tested (0.5s–5s) worked without elevated privileges

---

## Limitations

Doesn't cover intervals below 0.2s (may need root), flood mode (`-f`) interaction, packet loss/timeout scenarios (none occurred here), or non-ICMP (HTTP/port-level) connectivity.

---

## Conclusion

The `-i` flag governs packet pacing, not delivery success. Shorter intervals give denser samples faster; longer intervals spread the same samples over more time. Ctrl+C-terminated runs still produce accurate summary stats. Choosing an interval is a trade-off between sample density and load on the network/target.

---
*Generated from ICMP-based ping tests using the `-i` interval flag*