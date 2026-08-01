# Ping Output Analysis Notes — Numeric Flag (-n)

A learning-based network observation record studying the behavior of the `-n` (numeric output) flag in the `ping` command, comparing it directly against default (reverse-DNS-lookup) behavior across matching targets.

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
This directory contains raw output logs generated from the `ping` command executed on the same targets both with and without the `-n` flag, to directly compare their output formatting. The purpose is to study:

- What `-n` suppresses in ping's per-packet output
- Reverse-DNS lookup behavior when `-n` is absent
- Whether `-n` affects actual network performance (it should not)
- Side-by-side latency comparison for the same target under both modes

## Methodology

**Tool Used:** `ping` (ICMP Echo Request utility)

**Data Collection Method:** Each target was tested twice — once without `-n` (default) and once with `-n` — using the same count flag for a fair comparison. Output was saved into separate files for later analysis.

```
ping -c <count> <target> > <target>.txt          # without -n
ping -n -c <count> <target> > <target>.txt        # with -n
```

## Network Flow Understanding
Network communication in these tests follows the same underlying sequence, with one extra step when `-n` is *not* used:

```
DNS Resolution (forward) → IP Address → ICMP Request → Response → Reverse DNS Lookup (per reply, if -n absent)
```

By default, ping performs a **reverse DNS lookup** on the replying IP address for every single packet and prints the resolved hostname alongside the IP (e.g. `text-lb.eqsin.wikimedia.org (103.102.166.224)`). The `-n` flag disables this reverse lookup, printing only the numeric IP address for each reply. This is purely a display/formatting difference — it does not change how packets are sent, routed, or how many succeed.

## How to Read the Output
Compare the reply line format directly:

```
Without -n:  64 bytes from text-lb.eqsin.wikimedia.org (103.102.166.224): icmp_seq=1 ttl=57 time=91.7 ms
With -n:     64 bytes from 103.102.166.224: icmp_seq=1 ttl=57 time=92.5 ms
```

| Field | Without `-n` | With `-n` |
|---|---|---|
| Source identifier | Resolved hostname + IP in parentheses | IP address only |
| Lookup performed | Yes — one reverse DNS query per reply | No |
| `icmp_seq`, `ttl`, `time` | Identical in both modes | Identical in both modes |
| Summary statistics | Identical format in both modes | Identical format in both modes |

The reverse-lookup step happens independently for *each* reply, which is why `-n` can also make ping feel slightly more responsive on slow or unreliable DNS setups — there's no lookup to wait on before each line is printed.

## Test Results and Analysis

### 5.1 wikipedia.org — Without vs. With `-n` (`-c 10`)
| Property | Without `-n` | With `-n` |
|---|---|---|
| Resolved IP | 103.102.166.224 | 103.102.166.224 |
| Reverse Hostname Shown | text-lb.eqsin.wikimedia.org | *(not shown)* |
| Packets Sent | 10 | 10 |
| Packet Loss | 0% | 0% |
| Average Latency | 98.279 ms | 93.176 ms |
| Latency Range | 91.188 – 148.369 ms | 91.139 – 95.399 ms |
| Jitter (mdev) | 16.842 ms | 1.377 ms |

**Analysis:** Both runs reached the same resolved IP with 0% loss. The non-`-n` run shows a single latency spike (148 ms) that isn't present in the `-n` run, which is why its average and jitter are noticeably higher — this is normal run-to-run network variance rather than something caused by `-n` itself, since `-n` has no effect on packet timing.

### 5.2 facebook.com — Without vs. With `-n` (`-c 10`)
| Property | Without `-n` | With `-n` |
|---|---|---|
| Resolved IP | 157.240.227.35 | 157.240.227.35 |
| Reverse Hostname Shown | edge-star-mini-shv-01-mct1.facebook.com | *(not shown)* |
| Packets Sent | 10 | 10 |
| Packet Loss | 0% | 0% |
| Average Latency | 27.499 ms | 28.684 ms |
| Latency Range | 25.946 – 33.680 ms | 25.984 – 41.096 ms |
| Jitter (mdev) | 2.332 ms | 4.302 ms |

**Analysis:** Results are close between both runs, with the `-n` run actually showing a slightly higher outlier (41.1 ms on packet 10). This reinforces that any latency differences between the two modes are due to normal network variability between separate test runs, not the presence or absence of `-n`.

### 5.3 mit.edu — Without vs. With `-n` (`-c 10`)
| Property | Without `-n` | With `-n` |
|---|---|---|
| Resolved IP | 23.15.150.186 | 23.15.150.186 |
| Reverse Hostname Shown | a23-15-150-186.deploy.static.akamaitechnologies.com | *(not shown)* |
| Packets Sent | 10 | 10 |
| Packet Loss | 0% | 0% |
| Average Latency | 88.625 ms | 87.512 ms |
| Latency Range | 86.134 – 95.368 ms | 85.989 – 91.857 ms |
| Jitter (mdev) | 2.535 ms | 1.621 ms |

**Analysis:** Nearly identical performance in both modes. The reverse lookup for mit.edu resolved to an Akamai CDN hostname rather than an MIT-branded name, illustrating that reverse DNS reflects the actual infrastructure serving the reply (a CDN edge node), not necessarily the domain the user originally queried.

## Comparative Summary
| Target | Reverse Hostname (no `-n`) | Avg Latency (no `-n`) | Avg Latency (`-n`) | Loss (both) |
|---|---|---|---|---|
| wikipedia.org | text-lb.eqsin.wikimedia.org | 98.279 ms | 93.176 ms | 0% |
| facebook.com | edge-star-mini-shv-01-mct1.facebook.com | 27.499 ms | 28.684 ms | 0% |
| mit.edu | a23-15-150-186.deploy.static.akamaitechnologies.com | 88.625 ms | 87.512 ms | 0% |

## Key Findings
- `-n` suppresses the reverse-DNS hostname lookup that ping normally performs for every reply, printing only the numeric IP address instead.
- The underlying ICMP traffic, packet count, sequence numbers, TTL, and loss percentage are identical whether or not `-n` is used — it is a display-only flag.
- Reverse-DNS hostnames can reveal useful infrastructure details not obvious from the domain name alone — e.g. mit.edu's reply resolved to an Akamai CDN hostname, and facebook.com's reply resolved to a regionally-named edge server, both indicating CDN/edge delivery rather than a single origin server.
- Small latency differences between paired runs (e.g. wikipedia.org's 148 ms spike in the non-`-n` run) reflect normal variance between two separate test executions, not any effect of the `-n` flag itself.
- `-n` is commonly used in scripting or monitoring contexts where DNS lookups would add unnecessary latency to displaying results, or where only the IP address is needed for further processing.

## Limitations
This analysis is limited to ICMP-based testing only. It does not evaluate:
- HTTP/HTTPS availability
- Port-level connectivity
- Application performance
- Security configurations beyond ICMP behavior
- Cases where reverse DNS lookup itself fails or times out (not observed in this data set)

## Conclusion
These results confirm that `-n` is purely a cosmetic/display flag: it removes the per-reply reverse-DNS hostname, leaving only the numeric IP, without altering packet delivery, loss, or timing in any way. The reverse hostnames seen in the non-`-n` runs also provided useful context — such as identifying CDN edge nodes — that would otherwise be missed when using `-n`, making the choice between the two a trade-off between diagnostic detail and cleaner, faster output.

*Generated from ICMP-based ping tests using the -n flag*