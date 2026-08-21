## No database

This project's gate does not write to a database, so there is nothing to isolate per lane and any running services may be shared.

If that stops being true — the moment a test writes to a store another run reads — stop and say so rather than debugging the flakiness it produces. Set `ZENCHAIN_DB` to `sqlite` or `postgres` in `.zenchain/config.env` and run `zen render`; the isolation procedure is engine-specific and is not something to improvise mid-run. Two runs on one mutable store is not a degraded mode, it is a broken one.
