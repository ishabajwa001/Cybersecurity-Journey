# Ping Output Analysis Notes — Time To Live Flag (`-t`)
A learning-based network observation record studying the behavior of the `-t` (TTL) flag in the `ping` command against a single fixed target.

---

## Overview

This directory contains raw output logs from `ping` run against `mozilla.org` using different `-t` (TTL) values. TTL limits how many router hops a packet may cross before being discarded. The goal is to find the approximate hop distance to the target by testing low, medium, and high TTL values.

```bash
ping -t <ttl_value> -c <count> <target>
```

Every router along the path decrements the TTL by 1. If TTL hits 0 before reaching the destination, the packet is dropped and the router that dropped it sends back a **"Time to live exceeded"** ICMP message — note the *source* address on these replies is the intermediate router, not the final destination.

---

## Test Results and Analysis

### TTL 5 — too low

| Property | Result |
|----------|--------|
| Packets Sent | 10 |
| Result | 100% loss — "Time to live exceeded" from `10.253.4.40` on every packet |

Packets expired at the same router (`10.253.4.40`, an early internal/ISP hop) every time. 5 hops isn't enough to reach mozilla.org.

### TTL 7 — still too low

| Property | Result |
|----------|--------|
| Packets Sent | 5 |
| Result | 100% loss — "Time to live exceeded" from `72.14.211.72` on every packet |

Expired one hop further out (a Google-owned router, `72.14.211.72`), but consistently — meaning the real path is longer than 7 hops.

### TTL 8 — success

| Property | Result |
|----------|--------|
| Packets Sent | 5 |
| Packet Loss | 0% |
| Avg Latency | ~27.6 ms |

All 5 packets reached mozilla.org and returned. This suggests the destination is right around 8 hops away.

### TTL 10, 64, 128 — comfortably sufficient

| TTL | Packet Loss | Avg Latency |
|-----|-------------|--------------|
| 10  | 0% | ~27.1 ms |
| 64  | 0% | ~27.7 ms |
| 128 | 0% | ~29.3 ms |

Once TTL comfortably exceeds the real hop count, results stabilize — further increases just give the packet more headroom, with no effect on latency or success.

---

## Comparative Summary

| TTL | Outcome | Packet Loss | Notes |
|-----|---------|-------------|-------|
| 5   | Expired early | 100% | Dropped at hop `10.253.4.40` |
| 7   | Expired later | 100% | Dropped at hop `72.14.211.72` |
| 8   | Reached destination | 0% | Real hop count ≈ 8 |
| 10  | Reached destination | 0% | Stable |
| 64  | Reached destination | 0% | Stable |
| 128 | Reached destination | 0% | Stable, common Windows default |

---

## Key Findings

- `-t` sets the maximum number of hops a packet may cross before being discarded
- "Time to live exceeded" replies come from the router that dropped the packet, not the destination — its source IP shows roughly how far the packet got
- Raising TTL from too-low values moves the drop point progressively closer to the destination (`10.253.4.40` at TTL 5 → `72.14.211.72` at TTL 7)
- The real hop distance to mozilla.org is right around 8 — TTL 8 succeeds fully, TTL 7 fails completely
- Once TTL comfortably exceeds the real path length, results are stable and further TTL increases have no effect

---

## Limitations

Doesn't test TTL values above 128, or TTL's use in `traceroute`-style hop mapping.

---

## Conclusion

Testing `-t` at increasing values pinpointed mozilla.org's approximate hop distance at 8, based on where "Time to live exceeded" replies stopped appearing. TTL is a low-effort way to estimate path length or diagnose routing issues without a full traceroute, and the intermediate router addresses in exceeded replies help narrow down where along the path an issue exists.

---
*Generated from ICMP-based ping tests using the `-t` TTL flag*