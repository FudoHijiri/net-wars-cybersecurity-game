# NET WARS cheat sheet (all days)

For testing and balancing: the answers of every phase of Days 1 to 8, read from the game data. Spoilers.

**Every day:** Investigation > Monitoring > Hardening > Response > Recovery. Press `=` for the debug panel (skip to any phase, +SP, unlock all days, "win with every repair" in Response).

**Response in general:** play cards, then dodge. Block soaks hits, Dodge cancels a hit, Expose makes later cards hit harder. Equip the counter upgrade of each attack. The MUST upgrade of a day is the one without which the attacks come as undodgeable walls.

---

## Day 1 - An Unusual Login (Credential Abuse)

### 1. Investigation

Find the 4 clues (click lines to investigate, then MARK):

- **EMAIL**: Re: Why was my password changed?
- **LOGIN**: Anna signed in from Germany
- **FILES**: Payroll file copied
- **NETWORK**: File server to an outside computer

REPORT: In the middle of the night, someone used {1} to sign in from {2}. Then they copied {3} and sent it to {4}. All this time, Anna was fast asleep at home.

- {1} = Anna's account
- {2} = an unknown computer
- {3} = the payroll file
- {4} = an outside computer

### 2. Monitoring (REPORT a line that breaks a rule, LET PASS the rest)

- **Hours**: Sign in 08:00-18:00. REPORT when it was outside office hours. Bad example: 02:14.
- **Computers**: Listed computers only. Named for the owner: Ben's computer. Floor 2 printer: shared. REPORT when it came from an unlisted computer. Bad example: Unknown computer.
- **Place**: Sign in from the office. REPORT when it came from outside the office. Bad example: Germany.
- **Threat sign:** the computer "Unknown computer 7F3A" keeps coming back in the bad lines.
- **Looks bad but is fine (LET PASS):** {user} is on call. Any hour is fine. | Near closing. Still in hours. | Near opening. Still in hours. | One typo. Not an attack.

### 3. Hardening (upgrade load 2)

Upgrades of this day (* = recommended: answers a clue you can find):

- * **Unique Passwords** (load 1, 30 SP): ALWAYS: +10 max HP. AGAINST One password, many accounts: one stolen password opens nothing else.
- * **Two-step Sign-in** (load 1, 30 SP): ALWAYS: +3 Block at the start of each of your turns. AGAINST Stolen password: a stolen password alone is not enough to sign in.
-   **Lock After Failed Tries** (load 2, 50 SP): ALWAYS: Attack cards deal +2 damage. AGAINST Rapid guesses: too many wrong guesses lock the account.
- * **Unusual Sign-in Alerts** (load 2, 50 SP): ALWAYS: Draw 2 extra cards in your first hand. AGAINST Every attack: you are warned a little earlier when a sign-in looks strange.

**MUST equip: Two-step Sign-in** (without it the attacks cannot be dodged and every hit takes 30% of your HP).

### 4. Response - Credential Abuse (you 90 HP, threat 85 HP)

- **Rapid guesses**: The attacker tries password after password, very fast. Counter: Lock After Failed Tries.
- **One password, many accounts**: One common password is tried on every account. Counter: Unique Passwords.
- **Stolen password**: A leaked password works on the first try. No guessing needed. Counter: Two-step Sign-in.

### 5. Recovery

An attack that hits you in Response becomes a repair: Rapid guesses -> Give Anna her account back; Stolen password -> Undo the thief's changes; One password, many accounts -> Change the locks. The final check "Back to work" is always there.

- Give Anna her account back: approve REQUEST B (Office, in person), reject the other; password "river lantern orbit velvet"; then lock after wrong tries
- Undo the thief's changes: remove only what the thief did: Sent all her email to a stranger (02:14); Changed recovery phone to ...97 (02:16); Trusted its own computer (02:17)
- Change the locks: KEY: Summer2024; re-key the doors the stolen password opened: PERSONAL EMAIL, ONLINE SHOP
- Lock out the thief: remove only what the thief did: 02:43 (Unknown computer 7F3A); 03:10 (Unknown computer 7F3A)
- Reconnect safely: Drag each cleared cable to the socket with the same number and shape. You can also select a cable, then a socket.
- Restore a trustworthy backup: pick "B / CHECKED COPY", TEST it, then RESTORE (then the 3-2-1 step if it asks).

---

## Day 2 - A Slow Laptop (Malware)

_The first attack is over, but a laptop is slow and strange programs are running. Something got in. Find what it is._

### 1. Investigation

Find the 4 clues (click lines to investigate, then MARK):

- **EMAIL**: Invoice 4471 with a zip file
- **LOGS**: Antivirus turned off
- **COMPUTERS**: UpdateHelper.exe
- **NETWORK**: Ben's laptop calls an outside address

REPORT: Ben opened {1}. It installed {2}, switched off {3}, and then kept calling {4} every minute.

- {1} = the invoice attachment
- {2} = a program called UpdateHelper
- {3} = the antivirus
- {4} = an outside address

### 2. Monitoring (REPORT a line that breaks a rule, LET PASS the rest)

- **Programs**: Run approved programs only. Approved: Office Suite, Browser, PDF Reader, Backup Agent, Accounting Tool, DesignPro, Windows Update. REPORT when it is not on the approved list. Bad example: UpdateHelper.exe.
- **Source**: Programs come from IT or Windows Update. REPORT when it came from outside IT. Bad example: Email attachment.
- **Antivirus**: The antivirus must be on. Updating is allowed. It pauses itself for a few minutes. REPORT when it ran while the antivirus was off. Bad example: Off.
- **Threat sign:** the program "UpdateHelper.exe" keeps coming back in the bad lines.
- **Looks bad but is fine (LET PASS):** DesignPro is new, but it is on the approved list and came from the IT store. | Windows Update is approved. The odd hour does not matter. | The antivirus is updating. It is allowed for a few minutes.

### 3. Hardening (upgrade load 4)

Upgrades of this day (* = recommended: answers a clue you can find):

- * **Block Unknown Programs** (load 1, 30 SP): ALWAYS: +3 Block at the start of each of your turns. AGAINST Trojan: its disguise comes off at once, so you see what it is.
-   **Keep Software Updated** (load 1, 30 SP): ALWAYS: +10 max HP. AGAINST Worm: a copy can only split once.
- * **Antivirus Always On** (load 2, 50 SP): ALWAYS: Heal 4 HP at the start of each of your turns. AGAINST Spyware: the hidden bullets stay visible.
- * **Scan Attachments** (load 2, 50 SP): ALWAYS: Attack cards deal +2 damage. AGAINST Every attack: a longer warning before it starts.

**MUST equip: Antivirus Always On** (without it the attacks cannot be dodged and every hit takes 30% of your HP).

### 4. Response - Malware (you 90 HP, threat 100 HP)

- **Trojan**: It looks useful, like a free tool. It is not what it says. Counter: Block Unknown Programs.
- **Worm**: It copies itself to the next computer, and the next. Counter: Keep Software Updated.
- **Spyware**: It hides, and it watches what you type. Counter: Antivirus Always On.

### 5. Recovery

An attack that hits you in Response becomes a repair: Trojan -> Fix the blue screen; Worm -> Update the other laptops; Spyware -> Scan and clean. The final check "Back to work" is always there.

- Fix the blue screen: Ben's laptop crashes when it starts. Find out why, start it safely, and take the bad program off.
- Update the other laptops: The worm used a hole that an update would have closed. Turn updates on for every laptop that is out of date.
- Scan and clean: Spyware was hiding on Ben's laptop. Turn the protection back on, scan, then isolate only the real threats.

---

## Day 3 - Locked Out (Ransomware)

_Files are locked and a message demands payment. Find how it started, then get the company back to work._

### 1. Investigation

Find the 4 clues (click lines to investigate, then MARK):

- **EMAIL**: Parcel notice with a link
- **LOGS**: 612 files changed in 3 minutes
- **LOGIN**: Offline backup, 01:00
- **FILES**: Finance files renamed .locked

REPORT: First, {1}. Then, {2}. Then, {3}. Last, {4}.

- {1} = Marta clicked the link in the parcel notice (09:12)
- {2} = her files were locked (09:14)
- {3} = it spread to the shared Finance folder (09:16)
- {4} = a note asked for money (09:19)

### 2. Monitoring (REPORT a line that breaks a rule, LET PASS the rest)

- **Programs**: Only approved programs change files. Approved: Office Suite, Browser, PDF Reader, Backup Agent, Accounting Tool, DesignPro, Scanner. REPORT when it comes from a program nobody approved. Bad example: pay_now.exe.
- **Speed**: A person changes at most 20 files a minute. The Backup Agent may change many files at once: copying them is its job. Limit: 20. REPORT when it changes files far too fast. Bad example: 240.
- **Ending**: Files keep their usual ending (.docx, .xlsx, .pdf, .txt). .png is fine for a scanned page. REPORT when it gives files an ending they should not have. Bad example: .locked.
- **Threat sign:** the ending ".locked" keeps coming back in the bad lines.
- **Looks bad but is fine (LET PASS):** The Backup Agent is approved. It may change many files at once. | 18 files a minute is a lot for a person, but it is under the limit and the rest is in order. | A .png is fine for a scanned page, and the Scanner is approved.

### 3. Hardening (upgrade load 6)

Upgrades of this day (* = recommended: answers a clue you can find):

- * **Filter Suspicious Email** (load 1, 30 SP): ALWAYS: Attack cards deal +1 damage. AGAINST Every attack: a longer warning before it starts.
- * **Limit Shared Folders** (load 1, 30 SP): ALWAYS: Heal 2 HP at the start of each of your turns. AGAINST Mass lock: the lock cannot cross the wall between folders.
- * **Offline Backups** (load 2, 50 SP): ALWAYS: +1 Energy on your first turn. AGAINST Ransom demand: the demand bar never fills, because there is nothing to ask for.
-   **Encrypt Stored Data** (load 2, 50 SP): ALWAYS: +4 Block at the start of each of your turns. AGAINST Double extortion: the stolen copy is useless, so the second wave does not come.

**MUST equip: Offline Backups** (without it the attacks cannot be dodged and every hit takes 30% of your HP).

### 4. Response - Ransomware (you 90 HP, threat 110 HP)

- **Mass lock**: The lock spreads from one spot. Stay in the free part. Counter: Limit Shared Folders.
- **Ransom demand**: A bar fills as the demand grows. When it is full, a wall comes. Counter: Offline Backups.
- **Double extortion**: Two copies come, one from each side. Pay or be published. Counter: Encrypt Stored Data.

### 5. Recovery

An attack that hits you in Response becomes a repair: Mass lock -> Wipe and rebuild the laptop; Ransom demand -> Restore from the right backup; Double extortion -> Reopen the shared folders. The final check "Back to work" is always there.

- Wipe and rebuild the laptop: Unplug it from the network > Save the files you need, and scan them > Reinstall the system from a clean image > Install only approved programs > Restore your files > Reconnect it to the network
- Restore from the right backup: pick "01:00 Offline drive", TEST it, then RESTORE (then the 3-2-1 step if it asks).
- Reopen the shared folders: leave on only what each one needs, switch the rest off. Marta: finance; Dana: design; Carla: hr; Reception: nothing

---

## Day 4 - Wrong Door (Insider Threat)

_Someone with real access is doing something they should not. Look closely before you decide who._

### 1. Investigation

Find the 4 clues (click lines to investigate, then MARK):

- **EMAIL**: Fwd: Customer list, to a personal address
- **EMAIL**: Re: Victor's access
- **LOGS**: Victor opens Salaries
- **NETWORK**: 2 GB to a personal cloud

REPORT: From the logs we KNOW that {1}, {2}, {3} and {4}. We do NOT know {5} or {6}.

- {1}, {2}, {3}, {4} = any of: Victor opened the salary folder at 22:05 / 2 GB went to a personal cloud at 22:25 / the customer list was sent to a personal address / his old access was never removed
- {5}, {6} = any of: why he did it / whether anyone else has the files

### 2. Monitoring (REPORT a line that breaks a rule, LET PASS the rest)

- **Folders**: Each job opens only its own folders. Engineering: Projects, Design. Sales: Customers, Price lists. HR: HR files, Salaries. Finance: Finance, Invoices. IT: Servers, Backups. REPORT when it opens a folder that does not belong to the job. Bad example: Sales opens Salaries.
- **Hours**: Work happens between 07:00 and 19:00. REPORT when it happens far outside work hours. Bad example: 22:05.
- **Threat sign:** the folder "Salaries" keeps coming back in the bad lines.
- **Looks bad but is fine (LET PASS):** HR works with the salary folder. It is part of the job. | IT looks after the backups. It is part of the job. | 18:40 is near the end of the day, but it is still inside work hours.

### 3. Hardening (upgrade load 8)

Upgrades of this day (* = recommended: answers a clue you can find):

- * **Least Access** (load 1, 30 SP): ALWAYS: +10 max HP. AGAINST Trusted access: the bullets can only appear in the far part of the box.
- * **Unusual Activity Alerts** (load 1, 30 SP): ALWAYS: Heal 2 HP at the start of each of your turns. AGAINST Slow copy: an alert fires half way and the copying stops.
- * **Watch Outgoing Data** (load 2, 50 SP): ALWAYS: +5 Block at the start of each of your turns. AGAINST Walk-out: the carriers are slow, and the file they want is marked.
- * **Close Access on Exit** (load 2, 50 SP): ALWAYS: Draw 2 extra cards in your first hand. AGAINST Every attack: a longer warning before it starts.

**MUST equip: Least Access** (without it the attacks cannot be dodged and every hit takes 30% of your HP).

### 4. Response - Insider Threat (you 90 HP, threat 120 HP)

- **Trusted access**: A badge appears inside the box. Move away before it bursts. Counter: Least Access.
- **Slow copy**: A little at a time. Watch the COPIED bar. Counter: Unusual Activity Alerts.
- **Walk-out**: Stay near a file to guard it. Counter: Watch Outgoing Data.

### 5. Recovery

An attack that hits you in Response becomes a repair: Trusted access -> Take away the extra access; Slow copy -> Disable the account, then talk; Walk-out -> Get the file back. The final check "Back to work" is always there.

- Get the file back: pick "Yesterday 20:55 Version 41", TEST it, then RESTORE (then the 3-2-1 step if it asks).
- Take away the extra access: leave on only what each one needs, switch the rest off. Victor (Sales): customers; Omar (Eng.): projects; Nadia (HR): salaries; Lena (Sales): customers
- Disable the account, then talk: disable Victor's account; then talk: "Ask him in private, with HR there, and listen"

---

## Day 5 - Slow Leak (Data Exfiltration)

_Data is leaving the company, a little at a time. Find where it goes and who is sending it._

### 1. Investigation

Find the 5 clues (click lines to investigate, then MARK):

- **LOGS**: sync_cache, made by svc-report 11 days ago
- **LOGIN**: 198.51.100.23: not on the approved list
- **FILES**: tmp_cache.zip, 480 MB, in the temp folder of db-01
- **NETWORK**: 29 transfers of 2 MB to 198.51.100.23
- **SERVERS**: db-01: export at 03:10, 41,000 rows

REPORT: At {1}, the job {2} began copying {3}, {4}, to {5}.

- {1} = eleven nights ago, at 03:10
- {2} = sync_cache
- {3} = the customer table
- {4} = a little at a time, 2 MB every five minutes
- {5} = a host that is not on the approved list

### 2. Monitoring (REPORT a line that breaks a rule, LET PASS the rest)

- **Where**: Each computer may send only to its own approved places. db-01: the backup cloud. backup-01: the backup cloud. web-01: the update server, the analytics partner. mail-01: the mail relay. REPORT when it goes to a place that is not approved for that computer. Bad example: db-01 sends to 198.51.100.23.
- **How often**: A computer makes at most 6 transfers an hour. A steady trickle is a pattern. A person does not send data 12 times an hour. Limit: 6. REPORT when it is one of far too many in an hour. Bad example: 12.
- **Size**: Size is not a rule. It does not make a transfer good or bad. A huge backup can be fine, and a tiny trickle can be a leak. Bad example: 2 MB, db-01 to 198.51.100.23.
- **Threat sign:** the dest "198.51.100.23" keeps coming back in the bad lines.
- **Looks bad but is fine (LET PASS):** 9,000 MB is huge, but it is the nightly backup, and backup-01 may send to the backup cloud. | The analytics partner is approved for web-01, and one small upload an hour is its schedule. | 600 MB is a lot, but the update server is approved for web-01, and 2 an hour is few.

### 3. Hardening (upgrade load 10)

Upgrades of this day (* = recommended: answers a clue you can find):

- * **Approved Destinations Only** (load 1, 30 SP): ALWAYS: Attack cards deal +1 damage. AGAINST Quiet trickle: the leak is closed, so small bullets do not add Leak.
- * **Flag Odd Transfers** (load 1, 30 SP): ALWAYS: +3 Block at the start of each of your turns. AGAINST Big grab: it comes apart into three small pieces that do not home.
- * **Close Unused Ports** (load 2, 50 SP): ALWAYS: +20 max HP. AGAINST Hidden door: the lane about to fire lights up first.
- * **Label Sensitive Data** (load 2, 50 SP): ALWAYS: +1 Energy on your first turn. AGAINST Every attack: a longer warning before it starts.

**MUST equip: Approved Destinations Only** (without it the attacks cannot be dodged and every hit takes 30% of your HP).

### 4. Response - Data Exfiltration (you 90 HP, threat 125 HP)

- **Quiet trickle**: Each hit is tiny, but they add up at the start of your turn. Counter: Approved Destinations Only.
- **Big grab**: One big package follows you. Keep moving, or block it. Counter: Flag Odd Transfers.
- **Hidden door**: A lane fires without warning. Stay between the lanes. Counter: Close Unused Ports.

### 5. Recovery

An attack that hits you in Response becomes a repair: Hidden door -> Close the door: firewall rules; Quiet trickle -> Change the key: svc-report; Big grab -> Find what is left, then tell. The final check "Back to work" is always there.

- Close the door: firewall rules: leave on only what each one needs, switch the rest off. db-01: cloud; backup-01: cloud; web-01: updates, partner; Reception laptop: nothing
- Change the key: svc-report: Create a new, long password > Give the new password to the job that needs it > Test that the job still works > Disable the old password > Remove the old password from every place it was saved > Write down who owns the account
- Find what is left, then tell: disable tmp_cache.zip; then talk: "Tell the manager and the customers affected, plainly"

---

## Day 6 - Locked Door (Distributed Denial-of-Service)

_The website crawls under a flood of requests. Find the flood, keep customers in and the attacker out._

### 1. Investigation

Find the 5 clues (click lines to investigate, then MARK):

- **LOGS**: /search?q=, 41,000 requests a minute from 11:42
- **LOGS**: 97% of the requests use the browser name bot-kit/1.0
- **LOGIN**: The 9,200 addresses: 0 logins, 0 orders
- **NETWORK**: 41,000 requests a minute from 9,200 addresses, from 11:42
- **SERVERS**: web-01: processor at 100% since 11:43

REPORT: Graph A is {1}, and graph B is {2}. The flood began {3}. Every request asked for {4}, and none of them {5}.

- {1} = the real rush of customers
- {2} = the attack
- {3} = at 11:42, before the sale
- {4} = the same page, from one browser
- {5} = log in or buy anything

### 2. Monitoring (REPORT a line that breaks a rule, LET PASS the rest)

- **Requests a minute**: A big number does not decide. It does not make traffic good or bad. A sale can send 14,000 requests a minute, and all of them real. Bad example: 41,000 requests, 300 from each address.
- **From each address**: One visitor sends at most 40 requests a minute. Our own monitor may send more: checking the site is its job. Limit: 40. REPORT when it sends far too many requests from one address. Bad example: 420.
- **Pages**: Real visitors look around: the shop, a product, the cart, the checkout. A flood asks for one page, again and again. REPORT when it asks for only one page. Bad example: Only /search?q=.
- **Browser**: A real browser has a real name. friendly-bot/2.1 is the search engine's crawler: allowed, but worth a look. Our monitor is ours. REPORT when it comes from a browser name nobody real uses. Bad example: bot-kit/1.0.
- **Threat sign:** the pages "Only /search?q=" keeps coming back in the bad lines.
- **Looks bad but is fine (LET PASS):** 14,000 requests is a huge crowd, but it is the sale: 12 from each address, many pages, a real browser. | The search engine's crawler is polite and allowed. It is under the limit, and it reads many pages. | 600 requests from one address is a lot, but it is our own monitor checking the shop, and it is exempt.

### 3. Hardening (upgrade load 12)

Upgrades of this day (* = recommended: answers a clue you can find):

- * **Spread the Load** (load 1, 30 SP): ALWAYS: Heal 3 HP at the start of each of your turns. AGAINST Flood: the load is shared, so the bullets come from one side at a time.
- * **Limit Requests** (load 1, 30 SP): ALWAYS: +1 Dodge at the start of each of your turns. AGAINST Many sources: each source may fire only twice.
- * **Close Idle Connections** (load 2, 50 SP): ALWAYS: Attack cards deal +1 damage. AGAINST Slow drip: a held connection closes after 2.5 seconds.
- * **Spare Capacity** (load 2, 50 SP): ALWAYS: +10 max HP. AGAINST Every attack: a longer warning before it starts.

**MUST equip: Spread the Load** (without it the attacks cannot be dodged and every hit takes 30% of your HP).

### 4. Response - Distributed Denial-of-Service (you 90 HP, threat 130 HP)

- **Flood**: Too much at once from every side. Share it out. Counter: Spread the Load.
- **Many sources**: Thousands of senders. Cap each one. Counter: Limit Requests.
- **Slow drip**: Connections that never close fill the room. Counter: Close Idle Connections.

### 5. Recovery

An attack that hits you in Response becomes a repair: Flood -> Set a request limit + Cool the room, replace the fan; Many sources -> Block the attackers, not the customers; Slow drip -> Power-cycle the rack in order. The final check "Back to work" is always there.

- Set a request limit: The flood asks hundreds of times a minute from each address, and a real customer only a few. Move the limit so customers get in and the flood does not.
- Cool the room, replace the fan: The flood ran web-01 hot for an hour, and a fan gave up. First cool the room, then replace the fan the right way.
- Power-cycle the rack in order: Slow connections are stuck in the rack. Restart it in the right order: shut down from the top, then start up from the bottom.
- Block the attackers, not the customers: disable The 9,200 devices; then talk: "A short notice on the site: it was slow, it is fixed, sorry"

---

## Day 7 - Look Closer (Phishing)

_A message looks official, but something is off. Look closer, and find out who fell for it._

### 1. Investigation

Find the 5 clues (click lines to investigate, then MARK):

- **EMAIL**: Your password expires today, from c0mpany-it.com
- **LOGS**: Three people clicked the link, and one typed a password
- **LOGIN**: Ravi's account signed in at 09:35, from a new place
- **FILES**: The message's source: the text and the target disagree
- **NETWORK**: c0mpany-it.com was made 2 days ago and lives in another country

REPORT: Message {1} is the fake. Its sender is {2}, its link really goes to {3}, and it wants you to {4}. Ravi {5}.

- {1} = B
- {2} = c0mpany-it.com, with a zero
- {3} = a page on the look-alike domain
- {4} = type your password to keep it
- {5} = typed his password, and a thief signed in ten minutes later

### 2. Monitoring (REPORT a line that breaks a rule, LET PASS the rest)

- **Sender**: Mail may come only from our own domains. Ours: company-it.com, hr.company.com, training.company.com. A look-alike (a zero for an o, an r and an n for an m) is not ours. REPORT when it comes from a domain that only looks like ours. Bad example: c0mpany-it.com.
- **Link**: Each sender's links may go only to its own places. company-it.com: portal.company-it.com. hr.company.com: benefits-partner.example. training.company.com: learn.company.com. REPORT when it has a link that goes somewhere its sender should not send you. Bad example: company-it.com to c0mpany-it.com/login.
- **Request**: A message may ask you to read, or to open the portal yourself. A real notice never asks you to type a password into the message. REPORT when it asks for a password, a code or a payment. Bad example: Type your password here.
- **Sent at**: The time alone decides nothing. A fake can arrive at any hour. A real notice can come late, and a fake can come at lunch. Bad example: 09:12, from c0mpany-it.com.
- **Threat sign:** the sender "c0mpany-it.com" keeps coming back in the bad lines.
- **Looks bad but is fine (LET PASS):** That is the real IT reminder: our own domain, a link to our own portal, and it asks you to open the portal yourself. | HR may send you to the benefits partner: its domain is ours, and that link is on its list. | That is our own training test: our domain, and a link back to our own training site.

### 3. Hardening (upgrade load 14)

Upgrades of this day (* = recommended: answers a clue you can find):

- * **Check the Sender** (load 1, 30 SP): ALWAYS: +4 Block at the start of each of your turns. AGAINST Lure: every fake envelope carries a warning mark.
- * **Staff Training** (load 1, 30 SP): ALWAYS: Heal 2 HP at the start of each of your turns. AGAINST Fake login page: the page is shown as a hook from the start.
- * **Security Key** (load 2, 50 SP): ALWAYS: +15 max HP. AGAINST Stolen password: each hit does only a third of the damage.
- * **Report Button** (load 2, 50 SP): ALWAYS: +1 Energy on your first turn. AGAINST Every attack: a longer warning before it starts.

**MUST equip: Staff Training** (without it the attacks cannot be dodged and every hit takes 30% of your HP).

### 4. Response - Phishing (you 90 HP, threat 125 HP)

- **Lure**: Envelopes carry words. Read them before you touch one. Counter: Check the Sender.
- **Fake login page**: It looks like our sign-in page. It is not. Counter: Staff Training.
- **Stolen password**: A password you typed is theirs now. Counter: Security Key.

### 5. Recovery

An attack that hits you in Response becomes a repair: Lure -> Clean the inboxes, block, warn; Fake login page -> Give Ravi his account back; Stolen password -> Sign the thief out. The final check "Back to work" is always there.

- Clean the inboxes, block, warn: The fake email is in several inboxes. Remove every copy, stop the next one, and tell the staff what to look for.
- Give Ravi his account back: approve REQUEST B (Office, in person), reject the other; password "copper window harbor lemon"; then lock after wrong tries
- Sign the thief out: remove only what the thief did: 09:35 (Unknown computer 3C91); 09:50 (Unknown computer 3C91)

---

## Day 8 - Typed In (Web Application Attack)

_The customer portal shows odd errors and orders nobody placed. Someone typed their way in. Find out how._

### 1. Investigation

Find the 5 clues (click lines to investigate, then MARK):

- **LOGS**: ' OR 1=1 -- typed into the login form 40 times, from 14:02
- **COMPUTERS**: support_admin, an administrator made at 14:25
- **FILES**: help.php, a new file in the uploads folder at 14:20
- **NETWORK**: 198.51.100.80: the code at 14:02 and the sign-in at 14:31
- **SERVERS**: db-01: database errors went from 2 to 600 an hour at 14:00

REPORT: At {1}, someone typed {2} into the {3}. The website {4}, and the attacker left {5} behind.

- {1} = 14:02
- {2} = ' OR 1=1 --, a piece of code
- {3} = login form
- {4} = put it into its database question, and the database ran it
- {5} = a planted file and a new administrator

### 2. Monitoring (REPORT a line that breaks a rule, LET PASS the rest)

- **Sent by**: Who sends it decides nothing. A customer can be an attacker, and our own scanner is not one. Ours: the security team's scanner, every Tuesday. A customer may type anything into a box. Bad example: a customer, typing code.
- **Typed in**: The box decides nothing. Code can be typed into any box. The login form, the search box and the order form all take text. Bad example: the login name.
- **What was typed**: A name, a search or an order number is letters, digits and spaces. An apostrophe in a name is fine. Code is not. Our own scanner may type code: it is testing us on purpose. Look at the whole text, not at one character. REPORT when it has code in what was typed. Bad example: ' OR 1=1 --.
- **Answer**: A request gets back what it asked for: one row, a page, or a polite not found. Thousands of rows or a database error means the site did something it should not. REPORT when it got back thousands of rows or a database error. Bad example: 2,400 rows.
- **Threat sign:** the typed "' OR 1=1 --" keeps coming back in the bad lines.
- **Looks bad but is fine (LET PASS):** An apostrophe in a name is normal text: it is a customer called O'Brien, and the site showed his page. | That is the security team's own scanner, testing the site on purpose. It typed code, and the site refused it. | A long search is still letters and spaces. Nothing in it is code.

### 3. Hardening (upgrade load 16)

Upgrades of this day (* = recommended: answers a clue you can find):

- * **Check Input** (load 1, 30 SP): ALWAYS: +3 Block at the start of each of your turns. AGAINST Injection: a piece you touch is cleaned, so it cannot join another.
- * **Patch the Framework** (load 1, 30 SP): ALWAYS: +15 max HP. AGAINST Known hole: the bullet splits only once.
- * **Admin Lockdown** (load 2, 50 SP): ALWAYS: Heal 3 HP at the start of each of your turns. AGAINST Stolen admin: each hit does only a third of the damage.
- * **Web Firewall** (load 2, 50 SP): ALWAYS: Draw 2 extra cards in your first hand. AGAINST Every attack: a longer warning before it starts.

**MUST equip: Check Input** (without it the attacks cannot be dodged and every hit takes 30% of your HP).

### 4. Response - Web Application Attack (you 90 HP, threat 130 HP)

- **Injection**: Pieces are harmless alone. Do not hold a quote and a piece of code together. Counter: Check Input.
- **Known hole**: An old hole is open to everyone. Counter: Patch the Framework.
- **Stolen admin**: A new key to the master door. Counter: Admin Lockdown.

### 5. Recovery

An attack that hits you in Response becomes a repair: Injection -> Restore the website; Known hole -> Patch the hole, then prove it; Stolen admin -> Remove what the attacker left. The final check "Back to work" is always there.

- Restore the website: pick "Today 14:00 Version 64", TEST it, then RESTORE (then the 3-2-1 step if it asks).
- Patch the hole, then prove it: The login form still has the hole. Install the maker's update, but do it safely: back up, take the update from the maker, check it, test it on a copy, then do the real site.
- Remove what the attacker left: disable help.php; then talk: "support_admin (made 14:25, nobody asked)"

---
