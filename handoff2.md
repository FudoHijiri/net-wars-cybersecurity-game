# NET WARS — Handoff 2

## Project

**NET WARS** is a 2D pixel-art cybersecurity educational game made in Godot.

The target audience is players with little or no cybersecurity background. The game should teach basic cybersecurity concepts through understandable gameplay rather than feeling like a technical simulator.

The visual identity is a retro computer / CRT desktop environment with dark navy, blue, and cyan pixel-art styling.

## Core Gameplay

The planned gameplay phases are:

1. Investigation
2. Monitoring
3. Hardening
4. Response
5. Recovery

The game has 8 threat scenarios:

1. Credential Abuse
2. Malware
3. Ransomware
4. Insider Threat
5. Data Exfiltration
6. DDoS
7. Phishing
8. Web Application Attack

These are presented as Days with scenario-style titles, for example:

- Day 1 — An Unusual Login
- Day 2 — Something Got In
- Day 3 — Files Under Lock
- Day 4 — Someone Inside
- Day 5 — Data on the Move
- Day 6 — Under Heavy Load
- Day 7 — A Message to Trust
- Day 8 — The Open Door

## Navigation / Screens

The current general flow is:

**Desktop → Title Menu → Stage Select → Gameplay**

The desktop acts like an operating-system environment.

Stage Select currently includes:

- Resume
- New Game
- Day selection
- Back

The title menu remains a dedicated NET WARS title screen rather than immediately jumping into Stage Select.

## Accessibility

Accessibility is part of the project and is being implemented where it makes practical sense.

### Currently functional

**Colorblind Mode** uses an OptionButton with:

- 0 — Normal Vision
- 1 — Protanopia
- 2 — Protanomaly
- 3 — Deuteranopia
- 4 — Deuteranomaly
- 5 — Tritanopia
- 6 — Tritanomaly
- 7 — Achromatopsia
- 8 — Achromatopsia

### Current direction

UI scaling was removed because scaling the interface/text caused visual and layout problems.

High Contrast was also removed because a simple toggle that mainly increases saturation is not considered a good implementation.

Instead, visual/accessibility options being considered include:

- Colorblind Mode
- Disable Shaders
- Disable Dynamic Lighting

These are more appropriate to the game's visual design and can be useful for users who are sensitive to visual effects or need a simpler presentation.

Important accessibility principle: do not communicate important information through color alone. Use text, labels, icons, status words, or other visual indicators alongside colors.

## Investigation

Investigation is intended to be an actual evidence-gathering phase.

It should feel like the player is operating a compromised computer and examining information, rather than reading a conventional SOC dashboard.

The Investigation screen is implemented as a **Control/UI scene**, not a Node2D game-world scene.

The current visual concept is an investigation desktop with:

- Top objective bar
- Large central workspace
- Desktop-style investigation applications
- Bottom taskbar

Current investigation/evidence sources:

- Email
- Logs
- Login Activity
- Files
- Network
- Computers
- Servers

These are evidence sources rather than unrelated menu buttons.

### Distinction between Logs and Login Activity

**Login Activity** shows authentication/login history and helps identify suspicious access patterns.

**Logs** contain broader system events that can explain what happened before, during, and after the suspicious activity.

Example:

Login Activity:
- Successful login
- Failed login
- Successful login from unknown device

Logs:
- Authentication failure
- Authentication success
- Remote session created
- Privilege check
- External connection established

The purpose is to allow evidence from different sources to connect into a conclusion.

### Reports

Reports are **not considered another primary inspection source**.

The player gathers evidence from the investigation tools and then uses a report/conclusion step to summarize the findings and identify the threat.

Conceptually:

**Evidence Sources → Find Clues → Connect Evidence → Investigation Report → Identify Threat**

This prevents Reports from becoming redundant with the actual inspection tools.

## Investigation Gameplay Principle

The player should not simply open every application until the game reveals the answer.

The applications should contain clues that gradually establish what happened.

Example for Day 1 — An Unusual Login:

- Email: employee says they were not at the office.
- Login Activity: successful login from an unknown device.
- Logs: remote session was created.
- Network: connection to an unfamiliar external address.
- Files: sensitive file was accessed.

The player should infer the threat from the evidence.

## Monitoring

Monitoring is the second major phase after Investigation.

The previous handoff did not define a detailed Monitoring system yet. Treat its exact mechanics, interface, and gameplay loop as open design space unless newer project files or instructions specify them.

The intended direction is for Monitoring to feel like an active cybersecurity monitoring phase rather than simply repeating Investigation.

## Hardening / Response / Recovery

These systems are planned but should be designed around the same principle of being understandable to players without cybersecurity experience.

Response is intended to use a deck/card-inspired system similar to Slay the Spire.

The later phases may need additional design work, especially Response and Recovery, so avoid assuming the earlier prototype's exact implementation is final.

## Art / UI Direction

The project favors reusable pixel-art UI components over large amounts of one-off art.

Current visual priorities:

- Clear hierarchy
- Dark retro-computer interface
- Cyan/light-cyan accents
- Pixel-art buttons and panels
- Readable text
- Strong interaction feedback
- Avoid excessive neon/cyberpunk decoration

Most gameplay screens are UI-heavy and should generally use Godot `Control` nodes.

## Current Design Approach

Prefer:

- Simple systems
- Clear player objectives
- Gameplay that demonstrates the cybersecurity concept
- UI that looks like it belongs to the same computer environment
- Accessibility features that actually work
- Evidence-based gameplay instead of information dumping
- Reusable components

Avoid:

- Unnecessary technical complexity
- Generic cybersecurity dashboard designs
- Accessibility options that visibly break the UI
- Making every screen overloaded with information
- Adding features only for the sake of having more menu options

## Purpose of This Handoff

This document is intentionally not a complete technical specification.

It is context for future discussions about:

- UI design
- Scene layouts
- Gameplay ideas
- Accessibility
- Investigation design
- Monitoring design
- Threat scenarios
- General feature ideas

When proposing new ideas, preserve the overall NET WARS identity and avoid treating this handoff as a rigid final implementation specification.
