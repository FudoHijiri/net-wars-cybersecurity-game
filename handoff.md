# NET WARS — Claude Handoff

## Project Overview

**NET WARS** is a 2D pixel-art cybersecurity educational game being developed in Godot.

The goal is to teach basic cybersecurity concepts through approachable gameplay for players with little or no cybersecurity background. The game should feel like a game first, while naturally teaching investigation, monitoring, defense, and response concepts.

## Core Gameplay

The planned progression is:

1. Investigation
2. Monitoring
3. Hardening
4. Response
5. Recovery

Response is inspired by deck-building/card-game mechanics, while the earlier phases focus more on investigation and decision-making.

The current threat progression has 8 scenarios:

1. Credential Abuse
2. Malware
3. Ransomware
4. Insider Threat
5. Data Exfiltration
6. DDoS
7. Phishing
8. Web Application Attack

Each scenario can be presented as a "Day" with a descriptive title, such as:

- Day 1 — An Unusual Login
- Day 2 — Something Got In
- Day 3 — Files Under Lock
- Day 4 — Someone Inside
- Day 5 — Data on the Move
- Day 6 — Under Heavy Load
- Day 7 — A Message to Trust
- Day 8 — The Open Door

## Visual Direction

The visual identity is:

- 2D pixel art
- Retro computer / CRT / desktop interface
- Cybersecurity/IT theme
- Dark navy and blue foundation
- Cyan/light-cyan accents
- Pixel-style typography
- Functional computer UI rather than generic neon cyberpunk

The interface should feel like the player is operating an old computer system.

The game should avoid excessive neon, overly complex decoration, or unnecessary visual effects. Clarity is more important than visual density.

## Current Navigation Concept

The overall structure is roughly:

**Desktop → Title Menu → Stage Select → Gameplay**

The desktop acts like an operating-system environment.

The player can access things such as:

- Play
- Settings
- Exit

The title menu is a dedicated NET WARS title screen.

Stage Select currently has:

- Resume
- New Game
- Day selection
- Back

Settings are primarily focused on accessibility.

## Accessibility

Accessibility is an important part of the project rather than an afterthought.

Currently implemented/planned:

- **Colorblind Mode** — functional
  - Normal Vision
  - Protanopia
  - Protanomaly
  - Deuteranopia
  - Deuteranomaly
  - Tritanopia
  - Tritanomaly
  - Achromatopsia
  - Achromatomaly
- **UI & Text Scale** — intended to scale the interface and text together so text does not outgrow its UI containers.
- **Reduce Screen Effects** — intended as an accessibility option.

Color should not be the only way important information is communicated. Use text, icons, labels, and other visual indicators alongside colors.

## Investigation Direction

The Investigation screen is being built as a **Control/UI scene**, not a Node2D gameplay world.

The current visual direction is an investigation desktop:

- Large central workspace
- Desktop-style investigation applications
- Top objective bar
- Bottom taskbar
- Investigation tools such as:
  - Email
  - Logs
  - Computers
  - Login Activity
  - Files
  - Network
  - Servers
  - Reports

The intended gameplay loop is:

**Open an investigation application → inspect evidence → find clues → connect information → identify the threat → submit the investigation.**

Investigation should feel like actually operating a compromised computer rather than simply reading a cybersecurity dashboard.

For example, Day 1 may involve discovering suspicious logins, an unknown device, and other evidence that points toward credential abuse.

## Current Development Priorities

The project is beyond the initial concept stage and now needs coherent, functional prototype systems.

Priorities are generally:

1. Build strong and understandable gameplay/UI flows.
2. Keep the retro-computer identity consistent.
3. Make accessibility features meaningful.
4. Prototype the core gameplay before spending too much time on final artwork.
5. Improve Investigation and Monitoring first.
6. Eventually strengthen Hardening, Response, and Recovery.

The deadline was moved from October 3 to **October 9, 2026**, giving additional time for development and refinement.

## Design Principles

When suggesting designs or mechanics:

- Prefer simple, understandable systems.
- Avoid unnecessary complexity.
- Keep cybersecurity concepts understandable to non-experts.
- Make the game feel cohesive rather than like several unrelated menus.
- Preserve the retro-computer concept.
- Favor gameplay interactions over decorative UI.
- Accessibility should be considered in actual interaction design, not just settings.
- Do not over-engineer features when a simpler implementation communicates the idea better.

This document is primarily context for future **design, UI, gameplay, accessibility, and feature ideation**. Detailed implementation decisions should be made based on the current project state rather than assumed from this handoff.
