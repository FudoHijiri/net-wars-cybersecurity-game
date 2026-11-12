# The pre-game and post-game assessment: how it works and how to connect the Google Sheet

## What the game does

- **Pre-test:** the first time a save slot is opened, before the day select, the player writes an alias, agrees to the data being sent, and answers 12 scenario questions (`data/assessment.json`). Nothing in the game can be opened before it is done.
- **Post-test:** the same 12 questions, in a new order, at the end of Day 8 (after the ending), or earlier from the small **Study** button at the bottom-left edge of the day select (same place and look as Credits in the title menu). It opens a pop-up with Pre-test, Post-test, Feedback and Close, each marked done, due or later; only the part that is due can be opened. The button is not there once all three are done. Use it when a playtest session ends before Day 8.
- **Feedback form:** right after the post-test, 14 statements about the game rated from 1 (strongly disagree) to 5 (strongly agree), 4 to a page, and an optional comment (`data/feedback.json`). Each statement belongs to an ISO/IEC 25010 characteristic (functional suitability, performance efficiency, compatibility, usability, reliability, security) or to one of the subjects of Objective 5 (accessibility, gameplay experience, cybersecurity understanding). If a player leaves after the post-test, the Feedback item of the Study pop-up stays open until the form is done. Maintainability and portability are not asked: only an IT expert can judge them (use a short checklist for the adviser).
- The questions never say which answer is right, in either test. The order of the questions and of the options is random each time.
- **Once per person, not once per save slot.** The computer remembers who has answered what in an encrypted file outside the save slots (`user://study_profiles.dat`, one profile per alias). A new save slot first asks "who is playing?": the player picks their alias and the slot takes over what that alias has done (nothing is asked and nothing is sent again), or picks "I am new here" and takes the pre-test with a new alias. An alias can be used by one person on a computer. The post-test and the feedback form are also asked once per alias, wherever the player is in the game. So a player who makes a new save never sees a test again, and the sheet gets each result once.
- Each result (one per test per player) is saved in the save slot (encrypted and tamper-checked like the rest of the save), copied to `user://assessment/` as a JSON file, and sent to the Google Sheet. If it cannot be sent (no internet, or the school network blocks it) it waits in the slot's `outbox` and is sent again by itself every 30 seconds and every time the day select opens. The player is never stopped by the sending.
- Sent per result: alias, phase, score, which option each question got and whether it was right, the total time, the furthest day, how many phases were done, the game version, the time. No name, no e-mail, no computer information.

## Connecting the Google Sheet

1. Make a new Google Sheet (for example "NetWars assessment"). Leave it empty.
2. In the sheet: **Extensions > Apps Script**. Delete the code that is there, paste all of `tools/google_apps_script/Code.gs`, and change `KEY` to a word of your own (at least 12 random characters).
3. **Deploy > New deployment**. Click the gear next to "Select type" and choose **Web app**. Set *Execute as*: **Me**, *Who has access*: **Anyone**. Click **Deploy** and allow the permissions it asks for (Google shows a warning for scripts you wrote yourself: *Advanced > Go to ... (unsafe)* is normal here).
4. Copy the **Web app URL**. It ends with `/exec`.
5. In the game, open `data/assessment_config.json` and set:
   - `"endpoint"`: the URL you copied.
   - `"key"`: the same word as `KEY` in the script.
6. Test: open the URL in a browser; it should show `{"ok":true,"service":"netwars-assessment"}`. Then play a new save through the pre-test; a row appears in the sheet tab **Results** and the done page of the game says "Your answers were sent to the study."
7. After you change the script, use **Deploy > Manage deployments > edit (pencil) > Version: New version > Deploy**. The URL stays the same. (Editing the code without a new version changes nothing for the game.)

The workbook gets two tabs by itself, the first time a result arrives:

- **Results** has one row per pre-test or post-test: `received, session, phase, alias, score, total, seconds, day_reached, phases_done, version, played_at`, then `q01_correct ... q12_correct` (1 or 0), `q01_choice ... q12_choice` (A to D, the place of the option in `assessment.json`) and `attempt` (1 for the first result of that alias and phase, 2 for a repeat).
- **Feedback** has one row per player: `received, session, alias, version, played_at, f01 ... f14` (the ratings 1 to 5) and `comment`.

### Pre/post table for the analysis

Make a second tab **Summary** with these formulas (row 1 has the titles `alias, pre, post, gain`):

- `A2`: `=UNIQUE(FILTER(Results!D2:D, Results!D2:D<>""))`
- `B2`: `=IFERROR(MAXIFS(Results!E:E, Results!D:D, A2, Results!C:C, "pre"), "")`
- `C2`: `=IFERROR(MAXIFS(Results!E:E, Results!D:D, A2, Results!C:C, "post"), "")`
- `D2`: `=IF(AND(B2<>"", C2<>""), C2-B2, "")`

Fill B2:D2 down. Two players who use the same alias are merged, so ask the players to use different ones.

### Feedback by ISO 25010 characteristic

The characteristic of each statement is in `data/feedback.json`. For a table of the average rating of each characteristic, add a tab **Feedback summary** with the characteristic names in column A and, in column B, the average of the columns of its statements, for example:

- functional suitability (f01, f03): `=AVERAGE(Feedback!F2:F, Feedback!H2:H)`
- cybersecurity understanding (f02): `=AVERAGE(Feedback!G2:G)`
- performance efficiency (f04): `=AVERAGE(Feedback!I2:I)`
- compatibility (f05): `=AVERAGE(Feedback!J2:J)`
- usability (f06, f07, f08): `=AVERAGE(Feedback!K2:M)`
- accessibility (f09): `=AVERAGE(Feedback!N2:N)`
- reliability (f10, f11): `=AVERAGE(Feedback!O2:P)`
- security (f12): `=AVERAGE(Feedback!Q2:Q)`
- gameplay experience (f13, f14): `=AVERAGE(Feedback!R2:S)`

(Column F of the Feedback tab is f01, G is f02, and so on up to S for f14.)

## Things to know

- **The key is not a secret.** It is in the game files, so anyone who unpacks the game can read it. It only stops random posts to the address. The script also refuses anything that does not look like a result (alias, phase, score and answers are checked), and nobody can read the sheet through the address.
- **The scope of the paper.** The approved Scope and Limitation says that no player data is transmitted to or stored on external servers. This feature sends the alias and answers to Google. Tell the adviser and the panel, and change that sentence (the consent text in the game already says what is sent).
- **Several people on one computer:** each uses their own alias, and picks it when they start a new save. For a new group of participants on the same computer, forget the old aliases: press `=` for the debug panel and use *Forget study aliases (this computer)*, or delete `study_profiles.dat` from the folder below. Someone who deletes that file (or plays on another computer) can answer again; the sheet keeps the extra rows and its `attempt` column says 2, 3... for them, so use the rows with attempt 1.
- **A test without internet:** leave `endpoint` empty. The results stay in the save and in `user://assessment/` (on Windows: `%APPDATA%\Godot\app_userdata\NetWars Cybersecurity Game\assessment\`), and the done page says "saved on this computer".
- **Changing a question:** edit `data/assessment.json` and keep its `id`, as the sheet columns are the ids. If the number of questions changes, change `QUESTIONS` in the script too. Changing a question during the study changes what the scores mean.
- **Re-deploy after the update:** if you deployed the script before the feedback form was added, paste the new `Code.gs` again and deploy a new version (step 7), or the feedback rows are refused.
- **How it was tested:** against a stand-in of the Apps Script (same redirect after the POST) with the server working, down, refusing the key, and receiving the same result twice, and with the pre-test, the post-test and the feedback form one after the other. It has not been tested against Google itself; step 6 is the first real test.
