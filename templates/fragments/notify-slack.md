### Notify the human once, when the run ends

The human is not watching an unattended run. Send them **one** message the moment the PRD run reaches its checkpoint — whether it passed, stopped, or escalated — so they know it needs them without sitting on the terminal. One notification per run, at the end, never for per-issue progress.

Post it to `{{SLACK_CHANNEL}}` through the pipeline's Incoming Webhook{{SLACK_MENTION_CLAUSE}}. The webhook posts as a named app, not as the human, and needs no OAuth — so it works in a headless run where an interactive Slack connector would be absent. This is the human's standing authorisation for pipeline self-notification: a status ping to their own project channel, not an outward-facing message, so it does not need a fresh per-send confirmation.

The URL lives in `{{SLACK_ENV}}`. Build the JSON with `jq` so the multi-line body escapes cleanly, then one-shot curl — the webhook is bound to its channel, so no channel id is needed:

```
read -r -d '' TEXT <<'EOF'
:white_check_mark:  *{{PROJECT}} pipeline · <prd> — PASS*
{{MENTION_LINE}}

• *Gate:*  green
• *Decisions:*  none to review
• *Next:*  safe to start *<next>*
EOF
curl -fsS -X POST -H 'Content-type: application/json' \
  --data "$(jq -n --arg t "$TEXT" '{text:$t}')" "${{SLACK_ENV}}"
```

**If `{{SLACK_ENV}}` is unset or the curl fails (non-zero exit or a non-`ok` body), fall back to printing the notification as the first thing in your terminal report** and say the post failed. Do not let a failed post swallow the notification. Never send both.

The message uses Slack `mrkdwn` — an emoji + `*bold title*` first line so it is scannable on a phone, the mention on its own line, then `•`-bulleted `*Label:*  value` fields. Keep it to those few lines. It states which of three states the run ended in, and always names what comes next:

- **Blocked — needs you.** QA failed its rounds, reference capture hit a limit, a **Stop and ask a human** item fired, or the decider refused something for having no reversal path. `:warning:  *… — STOPPED*`, then `• *Blocked:*` and `• *Needs:* your call before <next>`.
- **Passed, but decisions to review.** PASS, but the run made `Stakes: high` decision records, or built on an earlier record whose reversal cost has now changed. `:ballot_box_with_check:  *… — PASS*`, then `• *Review first:* N high-stakes decisions`.
- **Passed clean.** PASS, gate green, no high-stakes decisions pending. `:white_check_mark:`, as in the template above.

The notification never replaces the checkpoint. A PASS still **stops** here for the human; the notification only tells them the verdict and the next step, it does not authorise starting the next PRD unattended.

**Naming `<next>`** — take it from the build order: {{BUILD_ORDER_LINE}} If the next PRD still has an unbuilt sibling dependency, say what is still blocking it rather than naming it as clear.

