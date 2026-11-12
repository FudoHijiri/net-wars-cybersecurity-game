/**
 * NetWars assessment receiver (Google Apps Script, bound to the Google Sheet that keeps the results).
 * Setup: docs/assessment_setup.md. Deploy it as a web app (Execute as: Me, Who has access: Anyone) and put its URL and the
 * KEY below in data/assessment_config.json of the game.
 *
 * The game sends one POST per result. The pre-test and the post-test of a player are rows of the sheet "Results"; the
 * feedback form of a player is a row of the sheet "Feedback". A result that arrives twice (the game sends again when it did
 * not hear the answer) is kept once.
 */
const KEY = 'CHANGE-THIS-WORD'; // the same word as "key" in data/assessment_config.json
const QUESTIONS = 12;          // how many questions there are (q01 ... q12)
const FEEDBACK_ITEMS = 14;     // how many statements the feedback form has (f01 ... f14)
const RESULTS = 'Results';
const FEEDBACK = 'Feedback';

function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(20000);
    const data = JSON.parse(e.postData.contents);
    if (data.key !== KEY) return reply({ ok: false, error: 'key' });
    const problem = data.phase === 'feedback' ? checkFeedback(data) : check(data);
    if (problem) return reply({ ok: false, error: problem });
    return data.phase === 'feedback' ? saveFeedback(data) : saveResult(data);
  } catch (err) {
    return reply({ ok: false, error: String(err) });
  } finally {
    lock.releaseLock();
  }
}

/** Opening the web app address in a browser answers this: a way to see that the deployment works. */
function doGet() {
  return reply({ ok: true, service: 'netwars-assessment' });
}

// --- the pre-test and the post-test ---

function saveResult(data) {
  const sheet = sheetNamed(RESULTS, header());
  if (known(sheet, data.session, data.phase)) return reply({ ok: true, duplicate: true });
  const byId = {};
  for (const a of data.answers) byId[a.q] = a;
  const correct = [];
  const choice = [];
  for (let i = 1; i <= QUESTIONS; i++) {
    const a = byId['q' + pad(i)];
    correct.push(a ? (a.correct ? 1 : 0) : '');
    choice.push(a ? 'ABCD'.charAt(a.choice) : '');
  }
  sheet.appendRow([
    new Date(), data.session, data.phase, data.alias, data.score, data.total,
    Math.round(data.total_ms / 1000), data.day_reached, data.phases_done, data.version, data.time,
  ].concat(correct, choice, [attempt(sheet, data.alias, data.phase)]));
  return reply({ ok: true, duplicate: false });
}

function header() {
  const h = ['received', 'session', 'phase', 'alias', 'score', 'total', 'seconds', 'day_reached', 'phases_done', 'version', 'played_at'];
  for (let i = 1; i <= QUESTIONS; i++) h.push('q' + pad(i) + '_correct');
  for (let i = 1; i <= QUESTIONS; i++) h.push('q' + pad(i) + '_choice');
  h.push('attempt');
  return h;
}

/** Refuses what the game would never send (the sheet is open to anyone who knows the address and the key). */
function check(d) {
  if (typeof d.session !== 'string' || !/^[0-9a-f]{16}$/.test(d.session)) return 'session';
  if (d.phase !== 'pre' && d.phase !== 'post') return 'phase';
  if (typeof d.alias !== 'string' || !/^[A-Za-z0-9 ._-]{2,24}$/.test(d.alias)) return 'alias';
  if (!Number.isInteger(d.score) || !Number.isInteger(d.total) || d.score < 0 || d.score > d.total || d.total > 50) return 'score';
  if (!Array.isArray(d.answers) || d.answers.length > 50) return 'answers';
  for (const a of d.answers) {
    if (typeof a.q !== 'string' || !/^q\d\d$/.test(a.q) || !Number.isInteger(a.choice) || a.choice < 0 || a.choice > 3) return 'answer';
  }
  return '';
}

// --- the feedback form ---

function saveFeedback(data) {
  const sheet = sheetNamed(FEEDBACK, feedbackHeader());
  if (known(sheet, data.session, 'feedback')) return reply({ ok: true, duplicate: true });
  const byId = {};
  for (const r of data.ratings) byId[r.q] = r.value;
  const ratings = [];
  for (let i = 1; i <= FEEDBACK_ITEMS; i++) ratings.push(byId['f' + pad(i)] || '');
  sheet.appendRow([new Date(), data.session, data.alias, data.version, data.time].concat(ratings, [safeText(data.comment), attempt(sheet, data.alias, 'feedback')]));
  return reply({ ok: true, duplicate: false });
}

function feedbackHeader() {
  const h = ['received', 'session', 'alias', 'version', 'played_at'];
  for (let i = 1; i <= FEEDBACK_ITEMS; i++) h.push('f' + pad(i));
  h.push('comment');
  h.push('attempt');
  return h;
}

function checkFeedback(d) {
  if (typeof d.session !== 'string' || !/^[0-9a-f]{16}$/.test(d.session)) return 'session';
  if (typeof d.alias !== 'string' || !/^[A-Za-z0-9 ._-]{2,24}$/.test(d.alias)) return 'alias';
  if (!Array.isArray(d.ratings) || d.ratings.length > 50) return 'ratings';
  for (const r of d.ratings) {
    if (typeof r.q !== 'string' || !/^f\d\d$/.test(r.q) || !Number.isInteger(r.value) || r.value < 1 || r.value > 5) return 'rating';
  }
  if (typeof d.comment !== 'string' || d.comment.length > 300) return 'comment';
  return '';
}

/** A comment that starts with = + - or @ would be read as a formula by the sheet: a quote in front makes it text. */
function safeText(text) {
  return /^[=+\-@]/.test(text) ? "'" + text : text;
}

// --- shared ---

function sheetNamed(name, titles) {
  const book = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = book.getSheetByName(name) || book.insertSheet(name);
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(titles);
    sheet.setFrozenRows(1);
  }
  return sheet;
}

/** True when the sheet has a row of this session (and phase, when the sheet has a phase column). */
function known(sheet, session, phase) {
  const last = sheet.getLastRow();
  if (last < 2) return false;
  const phaseColumn = sheet.getName() === RESULTS;
  const rows = sheet.getRange(2, 2, last - 1, phaseColumn ? 2 : 1).getValues(); // session [, phase]
  for (const row of rows) {
    if (row[0] === session && (!phaseColumn || row[1] === phase)) return true;
  }
  return false;
}

/** 1 for the first result of this alias and phase, 2 for the next, and so on (the analysis uses the rows with attempt 1). */
function attempt(sheet, alias, phase) {
  const last = sheet.getLastRow();
  if (last < 2) return 1;
  const results = sheet.getName() === RESULTS;
  const rows = sheet.getRange(2, 3, last - 1, results ? 2 : 1).getValues(); // Results: phase, alias; Feedback: alias
  let count = 0;
  for (const row of rows) {
    const rowAlias = results ? row[1] : row[0];
    const rowPhase = results ? row[0] : 'feedback';
    if (String(rowAlias).toLowerCase() === alias.toLowerCase() && rowPhase === phase) count++;
  }
  return count + 1;
}

function pad(i) {
  return i < 10 ? '0' + i : String(i);
}

function reply(body) {
  return ContentService.createTextOutput(JSON.stringify(body)).setMimeType(ContentService.MimeType.JSON);
}
