### The checkpoint is in the terminal

There is no out-of-band notification configured, so the PRD checkpoint is the report you print. Make it findable: lead with the verdict, name what is blocked, and name what comes next.

If the human is running this unattended and wants a ping instead, set `ZENCHAIN_NOTIFY="slack"` or `ZENCHAIN_NOTIFY="push"` in `.zenchain/config.env` and re-run `zen render`.
