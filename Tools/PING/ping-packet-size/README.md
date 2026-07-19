# Ping Output Analysis Notes — Packet Size Flag (`-s`)
A learning-based network observation record studying the behavior of the `-s` (packet size) flag in the `ping` command against a single fixed target.

---

## Overview

This directory contains raw output logs from `ping` run against `1.1.1.1` using different `-s` (payload size, in bytes) values. `-s` sets the number of data bytes sent in each ICMP packet, on top of the standard 8-byte ICMP header and 20-byte IP header (28 bytes total overhead). The goal is to observe how payload size affects delivery, and to find the path's MTU limit.

```bash
ping -s <payload_bytes> -c <count> <target>
```

---

## How the 28 Bytes of Overhead Work

Every ping packet is made of three layers stacked together: the `-s` payload, an ICMP header, and an IP header wrapped around both.

| Layer | Size | Purpose |
|-------|------|---------|
| IP header | 20 bytes | Source/destination IP, TTL, protocol number, checksum — needed to route the packet across the network |
| ICMP header | 8 bytes | Type/code (echo request vs. reply), identifier, sequence number — needed for ping itself to work |
| Payload (`-s`) | variable | Filler data whose only job is to make the packet a specific size |

So `-s 1464` doesn't send a 1464-byte packet — it sends 1464 bytes of payload wrapped in 28 bytes of headers, for a **1492-byte packet on the wire**. That's why every row in this README lists "total size" as payload + 28. Linux's `ping` actually prints this for you in its startup line, e.g. `1464(1492) bytes of data` — the first number is payload, the second is the true on-the-wire size.

---

## MTU and the DF Flag

**MTU (Maximum Transmission Unit)** is the largest packet size a given link (Ethernet cable, Wi-Fi hop, DSL/PPPoE connection, etc.) is willing to carry in one piece. Standard Ethernet's MTU is 1500 bytes. Every device along a path can have a different MTU, and a packet has to fit within the *smallest* MTU of any link it crosses.

**DF (Don't Fragment)** is a single bit in the IP header. `ping` sets it by default on Linux. It tells every router along the way: "if this packet is too big for your link, do not split it into smaller pieces — reject it instead." Normally, oversized IP packets *can* be fragmented (chopped into smaller packets and reassembled at the destination), but DF disables that entirely for this packet.

Put together, MTU + DF explain the failures seen in this folder:

- A router or gateway checks the packet size against its own MTU.
- If the packet is too big **and** DF is set, the packet is not fragmented — it's dropped.
- A well-behaved device sends back an ICMP **"Fragmentation needed and DF set"** message naming its MTU (as `192.168.100.1` did at 1492 bytes for the 1472-byte-payload test). This is exactly how tools like `tracepath` or manual MTU-discovery scans find a path's true MTU.
- A less cooperative device (or a network path with multiple potential culprits) can simply drop the oversized packet with no notice at all — which is what happened with the single byte over MTU at `-s 1465`, and again at `-s 10000`.

This is also why `-s 1464` (1492 bytes total) works but `-s 1472` (1500 bytes total) doesn't: this particular connection's real link MTU is 1492 bytes, 8 bytes short of the "normal" 1500-byte Ethernet default — a telltale sign of a PPPoE connection, where the PPPoE encapsulation itself eats 8 bytes out of the usual Ethernet payload budget.

---

## Test Results and Analysis

### `-s 56` — default-sized payload

| Property | Result |
|----------|--------|
| Packets Sent | 10 |
| Packet Loss | 10% (1 packet missing, `icmp_seq=8`) |
| Avg Latency | ~9.17 ms |

56 bytes is ping's default payload size. The single dropped packet here looks like ordinary transient loss, not a size-related issue — everything else this small transmits reliably.

### `-s 500`, `-s 1000` — mid-range payloads

| Size | Packet Loss | Avg Latency |
|------|-------------|--------------|
| 500  | 0% | ~7.42 ms |
| 1000 | 0% | ~8.77 ms |

All delivered cleanly with no meaningful latency increase as size grows — well within the path's MTU, so no fragmentation is needed.

### `-s 10000` — far too large

| Property | Result |
|----------|--------|
| Packets Sent | 10 |
| Packet Loss | 100% |

A 10,000-byte payload is far larger than any link along the path can carry in one piece. No error message came back at all, unlike the MTU tests below — the oversized packets were likely silently discarded.

### `-s 1472` — one step too many

| Property | Result |
|----------|--------|
| Total Packet Size | 1500 bytes (1472 + 28 overhead) |
| Packet Loss | 100%, +1 error |
| Error | `Frag needed and DF set (mtu = 1492)` |

The local gateway (`192.168.100.1`) rejected this outright: total size (1500 bytes) exceeds the link's actual MTU of 1492 bytes, and the "Don't Fragment" (DF) bit ping sets by default means it can't be split up to fit — so it's bounced back with an explicit error instead of sent.

### `-s 1464` — fits exactly

| Property | Result |
|----------|--------|
| Total Packet Size | 1492 bytes (1464 + 28 overhead) |
| Packet Loss | 0% |
| Avg Latency | ~9.18 ms |

1464 bytes of payload plus 28 bytes of overhead lands exactly on the 1492-byte MTU, confirming this connection's real-world MTU (typical of a PPPoE-based link, which reserves overhead below the standard 1500-byte Ethernet MTU).

### `-s 1465` — one byte over, silently dropped

| Property | Result |
|----------|--------|
| Total Packet Size | 1493 bytes |
| Packet Loss | 100%, no error message shown |

Just one byte past the MTU, but this time nothing came back at all — no "Frag needed" notice like the 1472 test produced. This inconsistency (explicit error vs. silent drop) is common in real networks, since not every device on a path is configured to send back ICMP "too big" notices.

### `-s 0` — header only, no payload

| Property | Result |
|----------|--------|
| Packet Loss | 0% |
| Reply Size | 8 bytes (header only, no data) |

A payload of 0 still produces a valid ping — the 8-byte ICMP header is sent with no data attached, and 1.1.1.1 replies normally.

### `-s -1` — invalid

| Property | Result |
|----------|--------|
| Result | `ping: invalid argument: '-1': out of range: 0 <= value <= 2147483647` |

Negative sizes are rejected immediately; no packets are sent.

---

## Comparative Summary

| Size (bytes) | Total Size | Packet Loss | Notes |
|--------------|------------|-------------|-------|
| 0    | 28   | 0%   | Header only |
| 56   | 84   | 10%  | Default size, ordinary transient loss |
| 500  | 528  | 0%   | — |
| 1000 | 1028 | 0%   | — |
| 1464 | 1492 | 0%   | Exact MTU fit |
| 1465 | 1493 | 100% | 1 byte over MTU, silent drop |
| 1472 | 1500 | 100% | 8 bytes over MTU, explicit "Frag needed" error |
| 10000 | 10028 | 100% | Far oversized, silently discarded |

---

## Key Findings

- `-s` sets only the payload; total packet size is always payload + 28 bytes of ICMP/IP overhead
- This connection's real MTU is 1492 bytes (not the standard 1500), consistent with a PPPoE-style link
- Exceeding the MTU with the default DF (Don't Fragment) bit set causes failure rather than automatic fragmentation
- The failure mode isn't always the same: 8 bytes over MTU produced an explicit "Frag needed and DF set" error, while 1 byte over produced silent 100% loss with no error — device configuration along the path affects whether feedback comes back at all
- A payload of 0 is valid and still produces a normal (header-only) exchange
- Negative sizes are rejected as an invalid argument before any packet is sent

---

## Limitations

Doesn't test disabling the DF bit (which would allow fragmentation instead of failure), doesn't confirm whether the 10,000-byte and 1465-byte silent drops happened at the same device, and doesn't test sizes between 1465–1471 to find exactly where explicit errors start appearing.

---

## Conclusion

Varying `-s` traced out this connection's real-world MTU boundary at 1492 bytes and showed that oversized, DF-flagged packets fail rather than fragment — sometimes with a clear error, sometimes silently. Aside from that boundary, payload size from 0 up to 1464 bytes had no meaningful effect on reliability or latency.

---
*Generated from ICMP-based ping tests using the `-s` packet size flag*