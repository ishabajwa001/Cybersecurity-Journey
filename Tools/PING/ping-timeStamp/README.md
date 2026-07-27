# Ping Output Analysis Notes — TimeStamp Flag (-D)

A learning-based network observation record studying the behavior of the `-D`, `-f`, `-i`, and `-t` flags in the `ping` command across different target types.

## Table of Contents
- Overview
- Methodology
- Network Flow Understanding
- Test Results and Analysis
- Comparative Summary
- Key Findings
- Limitations
- Conclusion

## Overview
This directory contains raw output logs generated from the `ping` command executed on different network targets using timestamp (`-D`), flood (`-f`), interval (`-i`), and TTL-limited (`-t`) modes. The purpose is to study intermediate network behavior, including:

- Per-packet timestamping with `-D`
- High-rate flood testing with `-f`
- Custom send intervals with `-i`
- TTL-limited probing with `-t`
- Round-trip time (RTT) variation under load
- Packet loss and ICMP error interpretation
- Router-level ICMP responses (Time to Live exceeded)

## Methodology

**Tool Used:** `ping` (ICMP Echo Request utility)

**Data Collection Method:** Each target was tested using a combination of flags. Output was saved into separate files for later analysis.

```
ping -D -c <count> <target> > <target>.txt
sudo ping -f -D <target> > <target>-flood.txt
ping -D -i <interval> -c <count> <target> > <target>-interval.txt
ping -D -t <ttl> <target> > <target>-ttl.txt
```

## Network Flow Understanding
Network communication in these tests generally follows this sequence:

```
DNS Resolution → IP Address → ICMP Request → Response
```

The flags tested here modify *how* that request is sent or displayed, rather than whether it is sent:
- `-D` prefixes each reply with a Unix timestamp, useful for precise timing analysis.
- `-f` (flood mode, requires root) sends packets as fast as replies arrive or in rapid succession, stressing the path and surfacing packet loss under load.
- `-i` sets the interval between packets (default 1s); sub-second intervals increase send rate without full flooding.
- `-t` sets a low TTL, causing the packet to expire at an intermediate router rather than reaching the destination, which returns a "Time to live exceeded" ICMP message instead of an echo reply.

## Test Results and Analysis

### 5.1 Timestamped Run — yahoo.com (`-D -c 10`)
| Property | Result |
|---|---|
| Packets Sent | 10 |
| Resolved IP | 98.137.11.164 |
| ICMP Response | Success |
| Average Latency | ~292.9 ms |
| Latency Range | 289.192 – 299.565 ms |
| Jitter (mdev) | 2.883 ms |
| Packet Loss | 0% |

**Analysis:** All 10 packets returned successfully with consistent ~290 ms latency, typical of a longer-distance route. The `-D` timestamps show replies arriving roughly one second apart, confirming the default send interval and a stable, low-jitter path.

### 5.2 Flood Test — intel.com (`sudo ping -f -D`)
| Property | Result |
|---|---|
| Packets Transmitted | 296 |
| Packets Received | 0 |
| Errors | +280 |
| Packet Loss | 100% |
| Time | 4706 ms |

**Analysis:** The flood output is dominated by `E` markers rather than `.` markers, indicating that nearly every probe returned an error response (rather than being silently dropped). Combined with 0 packets received and 100% loss, this points to the destination or an intermediate device actively rejecting/blocking the flood traffic rather than a routing failure.

### 5.3 Flood Test — google.com (`sudo ping -f -D`)
| Property | Result |
|---|---|
| Packets Transmitted | 778 |
| Packets Received | 776 |
| Packet Loss | ~0.257% |
| Average Latency | ~26.988 ms |
| Latency Range | 23.706 – 70.783 ms |
| Jitter (mdev) | 4.074 ms |
| Pipe | 5 |
| ipg/ewma | 15.704 / 26.160 ms |

**Analysis:** Unlike intel.com, google.com sustained the flood well, replying to nearly all 778 packets sent in just over 12 seconds. The `pipe 5` value indicates up to 5 packets were in flight unacknowledged at once, and the low average RTT with occasional spikes (max 70.783 ms) suggests brief congestion moments under the high send rate rather than filtering.

### 5.4 Custom Interval — 1.1.1.1 (`-D -i 0.2 -c 20`)
| Property | Result |
|---|---|
| Packets Sent | 20 |
| Interval | 0.2 s |
| ICMP Response | Success |
| Average Latency | ~8.568 ms |
| Latency Range | 5.785 – 18.393 ms |
| Jitter (mdev) | 3.095 ms |
| Packet Loss | 0% |

**Analysis:** Sending at 5 packets/second (0.2 s interval) instead of the default 1/second still yielded 0% loss, confirming a responsive, low-latency path to 1.1.1.1. Latency variance is slightly higher than a default-interval run, consistent with occasional queuing at the faster send rate.

### 5.5 TTL-Limited Probe — 9.9.9.9 (`-D -t 5`)
| Property | Result |
|---|---|
| Packets Transmitted | 12 |
| Packets Received (echo) | 0 |
| Errors | +12 ("Time to live exceeded") |
| Responding Hop | 10.253.4.40 |
| Packet Loss | 100% |
| Time | 11019 ms |

**Analysis:** Every probe expired at the same intermediate hop (10.253.4.40) before reaching 9.9.9.9, returning "Time to live exceeded" instead of an echo reply. This is expected behavior for a TTL value too low to reach the destination — it confirms the path exists and is reachable at least as far as that hop, rather than indicating a failure.

## Comparative Summary
| Target | Flag(s) | Packets Sent | Received | Loss | Avg Latency | Interpretation |
|---|---|---|---|---|---|---|
| yahoo.com | `-D -c 10` | 10 | 10 | 0% | ~292.9 ms | Stable, higher-latency long-distance route |
| intel.com | `-f -D` (flood) | 296 | 0 | 100% | N/A | Destination/path rejecting flood traffic |
| google.com | `-f -D` (flood) | 778 | 776 | 0.26% | ~27.0 ms | Path sustains flood load well |
| 1.1.1.1 | `-D -i 0.2 -c 20` | 20 | 20 | 0% | ~8.6 ms | Fast, responsive path even at 5 pps |
| 9.9.9.9 | `-D -t 5` | 12 | 0 (12 TTL errors) | 100% | N/A | TTL expired at intermediate hop 10.253.4.40 |

## Key Findings
- `-D` adds a Unix timestamp to each reply line, enabling precise inter-packet timing analysis without external tools.
- `-f` (flood mode) requires elevated privileges and sends packets far faster than the default interval, making it useful for stress-testing a path — but results vary sharply by target: google.com absorbed the flood with minimal loss, while intel.com returned errors for nearly every packet.
- A 100% loss result under flood mode with a high `+errors` count (as with intel.com) suggests active rejection/filtering rather than a dead route, distinguishing it from silent packet loss.
- `-i` allows the send rate to be tuned independently of `-c`; sub-second intervals increase throughput and can reveal congestion-related jitter not visible at the default 1-second rate.
- `-t` deliberately limits how far a packet can travel; a low TTL causes routers along the path to return "Time to live exceeded" instead of forwarding the packet to its destination, which is a routing diagnostic rather than an error condition.
- The `pipe` and `ipg/ewma` statistics reported in flood mode describe how many packets were in flight and the effective inter-packet gap, offering insight into network responsiveness under load.

## Limitations
This analysis is limited to ICMP-based testing only. It does not evaluate:
- HTTP/HTTPS availability
- Port-level connectivity
- Application performance
- Security configurations beyond ICMP behavior
- Sustained flood behavior beyond the captured sample window

## Conclusion
These results build on the base `-c` flag findings by showing how timing (`-D`), rate (`-f`, `-i`), and hop limits (`-t`) affect ping's ability to characterize a network path. Flood testing in particular highlighted that identical loss percentages can have very different causes — active filtering (intel.com) versus load-related micro-loss (google.com) — while the TTL test demonstrated that a "failed" ping can still confirm partial path reachability. Understanding these distinctions is essential for effective network troubleshooting.

*Generated from ICMP-based ping tests using the -D, -f, -i, and -t flags*