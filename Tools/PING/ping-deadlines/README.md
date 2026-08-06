# Ping Output Analysis Notes — Deadline Flag (-w)

A learning-based network observation record studying the behavior of the `-w` (deadline) flag in the `ping` command across different target types.

## Table of Contents
- [Overview](#overview)
- [Methodology](#methodology)
- [Network Flow Understanding](#network-flow-understanding)
- [How to Read the Output](#how-to-read-the-output)
- [Test Results and Analysis](#test-results-and-analysis)
- [Comparative Summary](#comparative-summary)
- [Key Findings](#key-findings)
- [Limitations](#limitations)
- [Conclusion](#conclusion)

## Overview
This directory contains raw output logs generated from the `ping` command executed on different network targets using the `-w` (deadline) flag, without an explicit `-c` count in most cases. The purpose is to study:

- How `-w` limits the total elapsed time of a ping run, rather than the packet count
- What happens when the deadline is reached mid-run
- Argument validation for `-w` (integer-only requirement)
- How `-w` interacts with the default 1-second send interval

## Methodology

**Tool Used:** `ping` (ICMP Echo Request utility)

**Data Collection Method:** Each target was tested using `-w <seconds>` to cap the total run time. Output was saved into separate files for later analysis.

```
ping -w <deadline_seconds> <target> > <target>-<deadline>.txt
```

## Network Flow Understanding
Network communication in these tests follows the same underlying sequence, but `-w` adds a time-based stopping condition instead of (or in addition to) a packet-count one:

```
DNS Resolution → IP Address → ICMP Request → Response → repeat until deadline elapses
```

Unlike `-c` (which stops after a fixed number of packets regardless of how long that takes) or `-i` (which controls the gap between sends), `-w` sets a hard ceiling on the **total wall-clock time** ping is allowed to run, including waiting for the final reply. Once the deadline is reached, ping stops sending new packets and exits — even if a `-c` count hasn't been fully reached, and even if some in-flight packets haven't replied yet.

## How to Read the Output
Compare the summary lines to see how `-w` shaped each run:

```
--- x.com ping statistics ---
20 packets transmitted, 20 received, 0% packet loss, time 19246ms
```

| Field | Meaning |
|---|---|
| `packets transmitted` | How many packets were actually sent before the deadline cut off further sends. With no `-c`, this is determined entirely by how many fit within `-w` seconds at the default 1s interval. |
| `time` | Total elapsed time for the run, in milliseconds — this should land at or just under the `-w` value (converted to ms), confirming the deadline was respected. |
| `rtt min/avg/max/mdev` | Standard round-trip time statistics, unaffected by `-w` itself — only the number of samples contributing to them changes. |
| `ping: invalid argument: 'X'` | Printed instead of any ping output when the value passed to `-w` isn't valid — no packets are sent. |

## Test Results and Analysis

### 5.1 Long Deadline — twitter.com (`-w 100`)
| Property | Result |
|---|---|
| Resolved IP | 162.159.140.229 |
| Packets Sent | 100 |
| Packet Loss | 0% |
| Average Latency | 13.285 ms |
| Latency Range | 8.326 – 77.746 ms |
| Jitter (mdev) | 7.949 ms |
| Total Time | 99205 ms |

**Analysis:** With no `-c` specified, ping continued sending at the default 1-second interval until the 100-second deadline was nearly reached, completing exactly 100 packets in 99.2 seconds — effectively acting like `-c 100` here because the interval and deadline happened to align. A single sharp outlier (77.7 ms on packet 50) pulled the jitter noticeably higher than the otherwise tightly-clustered ~9–16 ms replies.

### 5.2 Short Deadline — x.com (`-w 20`)
| Property | Result |
|---|---|
| Resolved IP | 172.66.0.227 |
| Packets Sent | 20 |
| Packet Loss | 0% |
| Average Latency | 112.748 ms |
| Latency Range | 109.047 – 118.600 ms |
| Jitter (mdev) | 2.944 ms |
| Total Time | 19246 ms |

**Analysis:** A 20-second deadline at the default 1-second interval allowed for 20 packets, all of which succeeded with very consistent latency (jitter under 3 ms). The run ended at 19246 ms — just under the 20-second cap — showing the deadline stopped sending in time to let the last reply return before exiting.

### 5.3 Invalid Deadline — instagram.com (`-w 12.5`)
| Property | Result |
|---|---|
| ICMP Request | Not executed |
| Error | `ping: invalid argument: '12.5'` |

**Analysis:** `-w` requires a whole-number (integer) number of seconds; a decimal value like `12.5` is rejected outright before any DNS resolution or packet transmission occurs. This mirrors the strict integer validation seen with `-c` in earlier tests.

### 5.4 Deadline Cutting Off Mid-Run — gnu.org (`-w 10`)
| Property | Result |
|---|---|
| Resolved IP | 209.51.188.116 |
| Packets Sent | 9 |
| Packet Loss | 0% |
| Average Latency | 362.381 ms |
| Latency Range | 260.691 – 713.279 ms |
| Jitter (mdev) | 148.336 ms |
| Total Time | 9510 ms |

**Analysis:** This is the clearest demonstration of `-w` in action: with high per-packet latency (~260–713 ms) and a 1-second send interval, only 9 packets fit within the 10-second deadline instead of the 10 that would otherwise be expected — the 10th packet was never sent because doing so (plus waiting for its reply) would have exceeded the deadline. The first reply's 713 ms spike also dominates the average and jitter figures, showing how a single slow reply can skew statistics more heavily in short, high-latency runs.

## Comparative Summary
| Target | Deadline (`-w`) | Packets Sent | Loss | Avg Latency | Interpretation |
|---|---|---|---|---|---|
| twitter.com | 100s | 100 | 0% | 13.285 ms | Deadline and natural packet count aligned closely |
| x.com | 20s | 20 | 0% | 112.748 ms | Full expected count sent; consistent low jitter |
| instagram.com | 12.5s (invalid) | 0 | — | — | Rejected — `-w` must be an integer |
| gnu.org | 10s | 9 | 0% | 362.381 ms | High latency caused deadline to cut off one packet early |

## Key Findings
- `-w <seconds>` limits total run time, not packet count — with no `-c` set, the number of packets sent depends on how many fit within the deadline at the current send interval.
- `-w` must be a whole number; fractional values like `12.5` are rejected with `ping: invalid argument` and no packets are sent, just like invalid `-c` values.
- When per-packet latency is low relative to the deadline (x.com, twitter.com), the packet count reaches what you'd expect from `deadline ÷ interval`. When latency is high (gnu.org, ~260–713 ms per reply), the deadline can cut the run short by one or more packets compared to that naive expectation, since ping must also account for waiting on the final reply.
- `-w` and `-c` can be combined in principle — whichever limit is hit first ends the run — though none of these tests used both together.
- A single high-latency outlier can dominate the average and jitter in short runs (gnu.org, 9 samples) far more than in longer runs (twitter.com, 100 samples), since there are fewer data points to smooth it out.

## Limitations
This analysis is limited to ICMP-based testing only. It does not evaluate:
- HTTP/HTTPS availability
- Port-level connectivity
- Application performance
- Security configurations beyond ICMP behavior
- Combined use of `-w` together with `-c` or `-i` in the same run

## Conclusion
These results show that `-w` is a time-based safety net rather than a packet-count control: it guarantees a ping run will not exceed a fixed wall-clock duration, regardless of how many packets that allows for. On fast, low-latency paths this produces results nearly identical to using an equivalent `-c` value, but on slower or more variable paths (as with gnu.org) it can visibly reduce the packet count and skew summary statistics — an important distinction to keep in mind when comparing runs that used `-w` against runs that used `-c`.

*Generated from ICMP-based ping tests using the -w flag*