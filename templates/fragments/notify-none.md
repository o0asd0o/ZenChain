### The checkpoint is in the terminal

There is no out-of-band notification configured, so the PRD checkpoint is the report you print. Make it findable: lead with the verdict, name what is blocked, and name what comes next.

If the human is running this unattended and wants a ping instead, set `ORC2_NOTIFY="slack"` or `ORC2_NOTIFY="push"` in `.orc2/config.env` and re-run `orc2 render`.

