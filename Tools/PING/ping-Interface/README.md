# Ping Output Analysis Notes — Interface Flag (-I)

A learning-based network observation record studying the behavior of the `-I` (interface) flag in the `ping` command across different network interfaces.

## Table of Contents
- [Overview](#overview)
- [Methodology](#methodology)
- [Network Flow Understanding](#network-flow-understanding)
- [Test Results and Analysis](#test-results-and-analysis)
- [Comparative Summary](#comparative-summary)
- [Key Findings](#key-findings)
- [Limitations](#limitations)
- [Conclusion](#conclusion)

## Overview
This directory contains raw output logs generated from the `ping` command executed on the same and different destination targets while binding the outgoing traffic to specific network interfaces using the `-I` flag. The purpose is to study:

- Forcing ping traffic out through a named interface
- Behavior when a named interface does not exist
- Behavior when an interface is unsuitable for reaching a given destination
- Differences between physical, virtual, and loopback interfaces
- Latency and reliability differences depending on the interface used

## Methodology

**Tool Used:** `ping` (ICMP Echo Request utility)

**Data Collection Method:** Each target was tested by binding to a specific interface with `-I <interface>`. Output was saved into separate files for later analysis.

```
ping -I <interface> -c <count> <target> > <interface>-<target>.txt
```

## Network Flow Understanding
Network communication in these tests follows the same underlying sequence, with one addition:

```
Interface Selection → DNS Resolution (if needed) → IP Address → ICMP Request → Response
```

The `-I` flag forces the outgoing packet to be sent from a specific network interface (and, where relevant, its associated source IP) rather than letting the OS choose the default route automatically. This is useful for testing multi-homed systems (multiple NICs, VPNs, Docker bridges, loopback) but can fail or behave unexpectedly if:
- The named interface does not exist on the system
- The interface exists but has no valid route to the destination
- The interface's source address doesn't match what the destination network expects

## Test Results and Analysis

### 5.1 Physical Interface — eth0 → 8.8.8.8 (`-I eth0 -c 20`)
| Property | Result |
|---|---|
| Source | 172.22.52.152 (eth0) |
| Packets Sent | 20 |
| Packet Loss | 0% |
| Average Latency | 29.312 ms |
| Latency Range | 24.262 – 62.355 ms |
| Jitter (mdev) | 8.898 ms |

**Analysis:** eth0 successfully routed all 20 packets to 8.8.8.8 with generally low, consistent latency. A single outlier (62.355 ms) pulled the max and mdev up slightly, but overall the interface performed reliably as the primary route to the internet.

### 5.2 Non-Existent Interface — wlan0 → 8.8.8.8 (`-I wlan0 -c 20`)
| Property | Result |
|---|---|
| ICMP Request | Not executed |
| Error | `SO_BINDTODEVICE wlan0: No such device` |

**Analysis:** The system has no interface named `wlan0`, so the bind operation failed immediately and no packets were sent. This is a configuration-layer failure, not a network reachability issue.

### 5.3 Loopback Bound to External Target — lo → 8.8.8.8 (`-I lo -c 20`)
| Property | Result |
|---|---|
| Warning | Source address might be selected on device other than: lo |
| Packets Sent | 20 |
| Packets Received | 0 |
| Packet Loss | 100% |

**Analysis:** ping allowed the bind to `lo` but warned that the source address may not actually match the interface, since loopback (127.0.0.1) cannot route to an external address like 8.8.8.8. All 20 packets were sent but none received a reply, confirming loopback cannot reach external hosts.

### 5.4 Loopback Bound to Loopback Target — lo → 127.0.0.1 (`-I lo -c 20`)
| Property | Result |
|---|---|
| Source | 127.0.0.1 (lo) |
| Packets Sent | 20 |
| Packet Loss | 0% |
| Average Latency | 0.062 ms |
| Latency Range | 0.047 – 0.168 ms |
| Jitter (mdev) | 0.025 ms |

**Analysis:** When both the interface and destination are loopback, communication succeeds with sub-millisecond latency, confirming this test never leaves the local machine. This contrasts directly with 5.3, isolating the interface/destination mismatch as the cause of that failure.

### 5.5 Non-Existent Interface — docker → 8.8.8.8 (`-I docker -c 10`)
| Property | Result |
|---|---|
| ICMP Request | Not executed |
| Error | `SO_BINDTODEVICE docker: No such device` |

**Analysis:** `docker` is not a valid interface name on this system (the actual Docker bridge is named `docker0`), so the bind failed before any packets were sent — the same class of error as 5.2.

### 5.6 Docker Bridge to External Target — docker0 → 8.8.8.8 (`-I docker0 -c 10`)
| Property | Result |
|---|---|
| Source | 172.17.0.1 (docker0) |
| Packets Sent | 10 |
| Packets Received | 0 |
| Errors | +6 ("Destination Host Unreachable") |
| Packet Loss | 100% |
| Pipe | 4 |

**Analysis:** The Docker bridge interface has no route to the public internet, so 6 of the 10 packets returned explicit "Destination Host Unreachable" errors from the local device itself (172.17.0.1) rather than timing out silently. This confirms the bridge network is isolated from external routing.

### 5.7 Docker Bridge to Its Own Gateway — docker0 → 172.17.0.1 (`-I docker0 -c 10`)
| Property | Result |
|---|---|
| Source / Target | 172.17.0.1 (docker0) |
| Packets Sent | 10 |
| Packet Loss | 0% |
| Average Latency | 0.329 ms |
| Latency Range | 0.067 – 1.631 ms |
| Jitter (mdev) | 0.441 ms |

**Analysis:** Pinging the Docker bridge's own gateway address succeeds with very low latency, showing that docker0 functions correctly for local bridge traffic — its earlier failure (5.6) was specifically about lacking an external route, not a broken interface.

### 5.8 USB/Ethernet Adapter — enx00155dc9a257 → 8.8.8.8 (`-I enx00155dc9a257 -c 10`)
| Property | Result |
|---|---|
| Warning | Source address might be selected on device other than: enx00155dc9a257 |
| Source | 172.22.52.152 |
| Packets Sent | 10 |
| Packet Loss | 0% |
| Average Latency | 180.412 ms |
| Latency Range | 25.262 – 951.927 ms |
| Jitter (mdev) | 296.819 ms |

**Analysis:** All 10 packets succeeded, but two replies (525 ms and 952 ms) were dramatically slower than the rest (~25–30 ms), dragging the average and jitter far higher than any other interface tested. Combined with the source-address warning, this suggests the named adapter may not be the interface actually carrying the traffic, and/or the path experienced intermittent congestion or buffering delays.

## Comparative Summary
| Interface | Target | Packets Sent | Received | Loss | Avg Latency | Interpretation |
|---|---|---|---|---|---|---|
| eth0 | 8.8.8.8 | 20 | 20 | 0% | 29.312 ms | Reliable primary route |
| wlan0 | 8.8.8.8 | — | — | — | — | Interface does not exist |
| lo | 8.8.8.8 | 20 | 0 | 100% | N/A | Loopback cannot reach external hosts |
| lo | 127.0.0.1 | 20 | 20 | 0% | 0.062 ms | Local-only traffic, sub-ms latency |
| docker | 8.8.8.8 | — | — | — | — | Interface does not exist (should be docker0) |
| docker0 | 8.8.8.8 | 10 | 0 | 100% | N/A | Bridge has no external route |
| docker0 | 172.17.0.1 | 10 | 10 | 0% | 0.329 ms | Bridge works correctly for local gateway |
| enx00155dc9a257 | 8.8.8.8 | 10 | 10 | 0% | 180.412 ms | Reaches internet but with erratic latency spikes |

## Key Findings
- `-I <interface>` requires the exact interface name as known to the OS; a typo or wrong guess (e.g. `wlan0`, `docker`) fails immediately with `SO_BINDTODEVICE ... No such device` before any packet is sent.
- Binding to an interface that exists but cannot route to the destination (loopback → external IP, Docker bridge → external IP) is accepted by ping but results in 100% loss, sometimes with an explicit "Destination Host Unreachable" error and sometimes with a silent warning about source address selection.
- Testing an interface against its "natural" target (loopback → 127.0.0.1, docker0 → its own gateway) confirms the interface itself is functioning correctly, isolating routing scope as the actual cause of failure in the mismatched cases.
- A "source address might be selected on device other than" warning does not always mean failure — enx00155dc9a257 still succeeded — but it signals the OS wasn't fully confident the specified interface would be used, which is worth investigating further if results look inconsistent.
- Large, isolated latency spikes on an otherwise-fast interface (as with enx00155dc9a257) can significantly skew average and jitter figures; reviewing the full range (min/max), not just the average, is important for accurate interpretation.
- The `pipe` statistic (seen with docker0 → 8.8.8.8) reflects in-flight unacknowledged packets and can appear even in error-heavy runs, not just successful high-rate ones.

## Limitations
This analysis is limited to ICMP-based testing only. It does not evaluate:
- HTTP/HTTPS availability
- Port-level connectivity
- Application performance
- Security configurations beyond ICMP behavior
- Root causes of the latency spikes observed on enx00155dc9a257 (e.g. Wi-Fi interference, power-saving states, driver behavior)

## Conclusion
These results show that `-I` is a useful diagnostic tool for isolating which interface is used for outbound traffic, but its success depends entirely on whether that interface actually has a valid route to the destination. Non-existent interfaces fail before any network activity occurs, existing-but-unrouted interfaces fail with 100% loss (sometimes with explicit unreachable errors), and correctly-matched interface/destination pairs succeed — with latency and jitter varying by the physical or virtual nature of the link. Understanding these distinctions helps pinpoint whether a connectivity issue is due to interface misconfiguration, routing scope, or the underlying link quality itself.

*Generated from ICMP-based ping tests using the -I flag*