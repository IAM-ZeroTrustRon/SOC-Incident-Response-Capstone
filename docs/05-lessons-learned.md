# Phase 5 — Risk Summary, Retrospective & AI-Assisted Workflow

## Risk, in plain business terms

This server had multiple unlocked "back doors" — unauthenticated ways in that
gave an attacker the same control as a system administrator, no password
required. Two were confirmed actively exploitable, not just theoretical.

In business terms, that exposure translates into four concrete risks:

- **Financial** — an attacker with full control could disrupt the business
  application, steal data, or use the box as a launch point into other
  systems, all of which carry direct cost to fix and potential liability.
- **Operational uptime** — the server hosts a business-critical application;
  an attacker (or even an uncontained response) could take it offline.
- **Brand and customer trust** — a breach involving unauthorized root-level
  access is hard to explain to customers or partners as anything other than
  a basic failure of care.
- **Compliance and audit exposure** — multiple long-unpatched, unauthenticated
  entry points on a production system is exactly the kind of finding that
  fails a security audit, independent of whether an attacker ever used it.

The outcome: every entry point was permanently closed at its actual source —
not just hidden behind a firewall — independently re-verified from an
attacker's vantage point, and backed by an automated check so a regression
is caught immediately rather than discovered the next time something breaks.

## Honest retrospective

**Environment discipline.** The biggest early time sink was simply keeping
track of which VM I was on — the analyst box and the target server run side
by side, and more than once I ran a fix or a check on the wrong one and got
a confusing result that had nothing to do with the actual problem. Lesson:
confirm the terminal prompt before trusting any output.

**The hardest technical challenge** was tracking down a backdoor with no
footprint in its expected configuration location. The standard place to
check showed nothing unusual, which briefly looked like a dead end. Getting
to the real answer meant working backward from the live network connection
itself — the process holding the port open, then that process's actual
startup command — before finding it was running from a much older, legacy
configuration file most modern checks wouldn't think to look at (full trace
in [`docs/04-eradicate-recover.md`](04-eradicate-recover.md)). It was a
genuine investigative process, not a lookup.

**A methodology mistake, documented rather than smoothed over.** My first
attempt at proving a port was truly closed (versus just firewall-blocked)
wasn't rigorous enough — I removed one specific firewall rule and assumed
that was sufficient, without realizing the firewall's overall default policy
was still silently blocking everything regardless of that one rule. The scan
result looked right, for the wrong reason. Catching it (full detail in
[`docs/03-contain.md`](03-contain.md#a-verification-mistake-worth-flagging))
changed how every subsequent fix was verified: fully disable the firewall
for a clean test, then restore it immediately after. A passing result isn't
the same as a correct test.

**Smaller friction that added up:** typos in in-place config edits that
failed silently or with a cryptic syntax error, and a script that broke the
moment it was pasted directly into a live shell instead of opened in an
editor first (see below). None were serious on their own, but they were a
consistent reminder that in this line of work, the small, unglamorous
mistakes are usually what eat the time — not the exotic ones.

## The role of AI in the investigation

Claude was used throughout as a virtual analyst — for narrowing down where
to look next, drafting commands and the health-check script, and turning
raw terminal output into organized documentation. Used well, it meaningfully
sped up the investigation: describing a listening port with no matching
config entry led to the suggestion of tracing the live process itself rather
than guessing at more config locations — the approach that actually found
the hidden backdoor, and a troubleshooting habit worth keeping generally.

It was just as instructive where it fell short. The clearest example is the
firewall-verification mistake above: the AI's suggested test looked complete
and was trusted at first, but it wasn't validated against how the firewall
actually behaves as a whole system — that gap had to be caught through my
own reasoning, not flagged by the AI first. It reinforced that "trust but
verify" isn't just a course rule; it's the actual difference between a fix
that works and one that only looks fixed on paper.

There was also a direct prompt-engineering lesson in how the AI was being
directed. Partway through, its evidence-tracking instructions had become
long, scattered, and genuinely hard to follow. Rather than push through it,
I stopped and told it plainly that it was overcomplicating things and needed
to be specific about exactly what to save and how to label it — the guidance
became short, exact, and usable for the rest of the phase immediately after.
That's a clean demonstration that AI output quality tracks the precision of
the prompt: vague or open-ended requests produced vague, sprawling answers,
and a direct correction fixed it right away.

The same pattern showed up with the health-check script itself: the first
version broke the moment it was pasted directly into a live `zsh` prompt —
`zsh: event not found: PORTS[@]` — because zsh's history-expansion
misinterprets `!` inside constructs like `${!PORTS[@]}`. Neither the prompt
nor the AI's response had specified the target shell environment up front.
The fix was simple once diagnosed (open the script in an editor first, paste
only the script content, save, then run it as a separate step), but a more
precise initial prompt would have caught the mismatch before it became a
debugging detour.

**Net effect:** AI made the mechanical and organizational parts of this
investigation faster — drafting, structuring, documenting — but every
meaningful judgment call still had to be mine, checked against the actual
system in front of me rather than how confident the AI's answer sounded.

### AI successes & failures at a glance

| Area | What worked | What didn't (corrected) |
|---|---|---|
| Root-cause tracing | Systematic ps → netstat/lsof → cmdline chain found two hidden backdoors with no obvious config-file trace | — |
| Verification methodology | — | Initial "closed vs. filtered" test only deleted one firewall rule — missed the default-DROP policy. Caught by manually checking the underlying firewall table, not by the AI flagging it first |
| Documentation & reporting | Converted raw terminal output into audit-ready tables and write-ups quickly, keeping pace with a fast-moving investigation | — |
| Evidence-tracking guidance | — | Early instructions became over-engineered and confusing; only usable after explicitly asking it to simplify |
| Script generation | Health-check logic (port sweep, SECURE/INSECURE output) was solid and correctly customized to the real target IP and ports | First version broke on a live shell — the prompt hadn't specified the shell environment, and the AI hadn't asked |

## About the AI-assisted workflow

Throughout this project, AI (Claude) was used strictly as a **virtual
analyst** — for drafting commands, proposing next investigative steps,
generating scripts, and structuring documentation. Every finding and every
fix was manually executed and verified against the live lab environment
before being treated as fact; nothing in this repository is AI output that
wasn't hands-on tested. That verification discipline is the actual subject
of this write-up as much as the vulnerabilities themselves.
