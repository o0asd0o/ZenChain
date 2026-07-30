### Notify the human once, when the run ends

The human is not watching an unattended run. Send **one** push notification the moment the PRD run reaches its checkpoint — whether it passed, stopped, or escalated. One per run, at the end, never for per-issue progress.

Use the `PushNotification` tool. Keep it to a title and a line: the verdict, and what it needs from them.

- **Blocked** — `{{PROJECT}} · <prd> STOPPED` / `<blocker> — needs your call before <next>`
- **Passed, decisions to review** — `{{PROJECT}} · <prd> PASS` / `N high-stakes decisions to review before <next>`
- **Passed clean** — `{{PROJECT}} · <prd> PASS` / `Gate green. Safe to start <next>.`

The full report still goes to the terminal; the push is the pointer, not the report.

The notification never replaces the checkpoint. A PASS still **stops** here for the human; the push only tells them the verdict, it does not authorise starting the next PRD unattended.

**Naming `<next>`** — take it from the build order: {{BUILD_ORDER_LINE}} If the next PRD still has an unbuilt sibling dependency, say what is still blocking it rather than naming it as clear.

