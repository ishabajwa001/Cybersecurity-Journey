# Defensive Security – TryHackMe Learning Notes

## Overview
Defensive security is the practice of protecting systems, detecting malicious activity, and responding to cyberattacks.  
Unlike offensive security, the focus is not on breaking systems but on monitoring and defending them in real time.

---

## Main Goal of Defensive Security
Detect and respond to attacks before they cause damage.

---

## Core Objectives
- Detect suspicious or unauthorized activity
- Investigate security alerts and logs
- Respond to active threats quickly
- Prevent escalation and data loss
- Strengthen system security after incidents

---

## Role of a SOC Analyst
A Security Operations Center (SOC) analyst is responsible for:
- Monitoring security dashboards
- Investigating alerts in real time
- Identifying malicious IP addresses
- Analyzing logs and traffic patterns
- Blocking or containing threats
- Reporting incidents and documenting findings

---

## Types of Defensive Security

### 1. Preventive Security
Stops attacks before they happen:
- Firewalls
- Authentication systems
- Access control policies
- System hardening

### 2. Detective Security
Identifies ongoing or past attacks:
- SIEM tools (log aggregation and analysis)
- Intrusion Detection Systems (IDS)
- Security monitoring dashboards

### 3. Responsive Security
Handles active threats:
- Incident response
- IP blocking
- System isolation
- Malware containment and removal

---

##  Common Security Tools
- SIEM platforms (e.g., Splunk)
- Firewall management systems
- Endpoint detection tools
- Log analysis dashboards
- Threat intelligence feeds

---

## TryHackMe Lab – Key Learning Points

### Monitoring Activity
- Security dashboards display real-time system activity
- Alerts highlight unusual or suspicious behavior

### Attack Behavior Observed
- Attackers often perform **URL discovery attempts**
  - Example paths: `/admin`, `/login`, `/backup`
- Logs help track attacker movements step-by-step

### Investigation Process
- Identify suspicious IP addresses from logs
- Analyze URL discovery attempts
- Determine attacker intent based on patterns

### Containment Step
- Block malicious IP addresses using firewall rules
- Example attacker IP:
  - `32.122.195.63`

---

## Key Insight
In defensive security, speed matters more than complexity.  
The goal is to **detect, analyze, and contain threats before damage spreads**.

---

## Summary
Defensive security is about continuous monitoring, fast investigation, and immediate response.  
It transforms raw logs into actionable decisions that protect systems from real-world attacks.