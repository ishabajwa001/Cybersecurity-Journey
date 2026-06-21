# Offensive Security

## Overview

Offensive security is the practice of actively testing systems, applications, and networks to identify security weaknesses before they can be exploited by real attackers.

It focuses on thinking like an attacker in a controlled and authorized environment.

## Purpose

* Discover vulnerabilities in systems
* Understand how attackers think and operate
* Improve overall security by exposing weak points
* Test the effectiveness of existing defenses

## Core Activities

### Reconnaissance

Gathering information about a target system, such as:

* IP addresses
* Services running
* Publicly exposed resources

### Enumeration

Actively extracting deeper details from a target:

* Hidden directories and files
* User accounts
* Open ports and services

### Vulnerability Identification

Finding security flaws such as:

* Misconfigurations
* Weak authentication
* Exposed sensitive data

### Exploitation (in controlled environments)

Attempting to take advantage of discovered vulnerabilities in a safe, authorized setup to understand impact.

## Ethical Hacking

Offensive security is performed by ethical hackers who:

* Work with permission
* Follow strict rules of engagement
* Do not cause unauthorized damage
* Report findings responsibly

## Common Tools

* DIRB (directory enumeration)
* Nmap (network scanning)
* Gobuster (web content discovery)
* Burp Suite (web application testing)
* Wireshark (network traffic analysis)

## Lab Context (TryHackMe)

In beginner offensive security labs, simulated environments are used to practice real attacker-style thinking in a safe and legal setup.

Typical tasks include:

* Finding hidden directories on a web application
* Identifying exposed or unlinked resources
* Understanding how attackers explore a target system step by step

## Key Takeaways

* I practiced a lab involving a simulated banking website environment
* Used DIRB to discover hidden directories that were not visible through normal navigation
* Learned how enumeration helps reveal hidden attack surfaces in web applications
* Understood that even simple misconfigurations can expose sensitive paths
