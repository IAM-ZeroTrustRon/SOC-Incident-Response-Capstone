# SOC Incident Response Capstone — Legacy Server Breach Investigation

A hands-on incident response case study: identifying, containing, and permanently
remediating multiple root-level backdoors on an intentionally vulnerable, unpatched
legacy Ubuntu server, using an AI tool (Claude) as an interactive "virtual analyst"
throughout — with every AI-suggested finding manually verified against the live
system before being treated as fact.

> **Context:** Completed as my individual contribution to a 5-person team capstone
> for PerScholas's *Module 195: Cybersecurity with AI Tools*. This repository
> documents my own hands-on investigation, remediation work, and AI-assisted
> workflow — not the team's combined submission. All target systems are
> intentionally vulnerable training VMs in an isolated lab network; no real
> production systems, data, or third parties were involved.

## Scenario

A legacy Ubuntu server supporting a fictional company's business-critical
application triggers a NOC alert for an anomalous traffic spike. Investigation
as the on-call analyst, working through the full incident response lifecycle:
**Prepare → Detect & Analyze → Contain → Eradicate & Recover → Report**.

## What was found

The server was running 30 open services with no evidence of patching. Two
independent, **unauthenticated root-level backdoors** were confirmed exploitable
— either one alone fully explains the incident — plus several additional
high-severity, independently exploitable vulnerabilities and non-essential
services quietly auto-starting at boot.

| Service | Port | Finding | Severity |
|---|---|---|---|
| vsftpd 2.3.4 | 21 | Trojaned backdoor (CVE-2011-2523) — exploit-verified, returns a root shell | Critical (9.8) |
| Ingreslock | 1524 | Legacy `inetd.conf` entry spawning an unauthenticated root shell on connect | Critical |
| distccd | 3632 | Remote code execution (CVE-2004-2687) — exploit-verified | Critical (9.3) |
| UnrealIRCd | 6667/6697 | Trojaned backdoor (CVE-2010-2075) | High (7.5) |
| Samba smbd | 139/445 | `username map script` command injection (CVE-2007-2447) | Medium (6.0) |
| Java RMI | 1099 | Insecure remote class loading, auto-started at boot | Confirmed |
| Apache httpd | 80/8180 | Slowloris DoS (CVE-2007-6750) | Confirmed |

Full CVE detail, verification method, and remediation steps for each finding are
in [`docs/02-detect-analyze.md`](docs/02-detect-analyze.md).

## What was done about it

1. **Prepare** — built and validated the isolated lab network, confirmed
   connectivity, ran a full port/service sweep. → [`docs/01-prepare.md`](docs/01-prepare.md)
2. **Detect & Analyze** — deep-vulnerability scan, manual CVE verification against
   NVD for every finding, attack path hypothesis. → [`docs/02-detect-analyze.md`](docs/02-detect-analyze.md)
3. **Contain** — captured volatile forensic evidence *before* any change to the
   system, then surgically firewalled both confirmed backdoors without taking the
   server offline. → [`docs/03-contain.md`](docs/03-contain.md)
4. **Eradicate & Recover** — traced every backdoor to its *actual* startup
   mechanism (not just the firewall) and permanently disabled it at the source;
   hardened the box by disabling four more non-essential auto-start services;
   built and debugged a custom automated health-check script.
   → [`docs/04-eradicate-recover.md`](docs/04-eradicate-recover.md)
5. **Report** — translated the technical findings into a plain-language risk
   summary for a non-technical audience, plus an honest retrospective on what
   went wrong and how AI was actually used (successes *and* failures).
   → [`docs/05-lessons-learned.md`](docs/05-lessons-learned.md)

## The interesting part: two "invisible" backdoors

Two of the confirmed backdoors had **no entry in the location you'd normally
check**. vsftpd was being managed by `xinetd` rather than as a normal systemd
service, so `service stop` / `apt-get purge` failed outright. The Ingreslock
bindshell was worse: it wasn't in `xinetd`'s config directory at all — it only
existed as a legacy `/etc/inetd.conf` entry that `xinetd` happened to still be
honoring via a compatibility flag. Finding it meant working backward from the
live listening port, to the process holding it open, to that process's actual
startup command, before the real config file turned up. Full trace in
[`docs/04-eradicate-recover.md`](docs/04-eradicate-recover.md).

There's also a firewall-verification lesson worth reading:
[`docs/03-contain.md`](docs/03-contain.md#a-verification-mistake-worth-flagging)
covers a real methodology mistake — a test that *looked* like it proved a port
was closed, but wasn't rigorous enough to actually prove it.

## Repository structure

```
docs/         Full write-up for each phase (methodology, findings, remediation)
scripts/      healthcheck.sh — the AI-assisted automated verification script
evidence/     Terminal screenshots supporting each phase's findings
```

## Tools & skills demonstrated

`nmap` (service/version detection, NSE vulnerability scripts) · NVD/CVE manual
verification · Linux service management (`xinetd`, `inetd.conf`, `rc.local`,
`init.d`) · host firewall configuration (`ufw`/`iptables`) · Bash scripting ·
volatile forensic evidence capture · VirtualBox lab network design · AI-assisted
("trust but verify") investigation workflow with Claude.

## Final deliverables

Project complete. The full team-submitted technical report (all 5 members,
Phases 1-5) and the non-technical executive presentation are included here for
portfolio reference:

- [`deliverables/CAP195_Technical_Report_FINAL.pdf`](deliverables/CAP195_Technical_Report_FINAL.pdf) / [`.docx`](deliverables/CAP195_Technical_Report_FINAL.docx) — full team technical report
- [`deliverables/CAP195_Executive_Presentation_FINAL.pptx`](deliverables/CAP195_Executive_Presentation_FINAL.pptx) — non-technical executive briefing deck

My own individual write-up per phase, with my own evidence, stays in
[`docs/`](docs/) as described below.

## Disclaimer

This project was performed entirely inside an isolated VM Oracle Box lab network
against intentionally vulnerable training targets, for educational purposes as
part of a cybersecurity certificate program. No commands, scripts, or techniques
in this repository were run against, or are intended for use against, any system
without explicit authorization.
