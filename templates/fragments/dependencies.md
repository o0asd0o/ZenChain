## Technical choices live in the issue packet

The current manifest, config, and schema are factual authority. An agent may use an already-installed dependency when it fits the acceptance criteria.

A new or replacement dependency, engine, service, or provider, and every major upgrade, must appear under the issue's `## Approved Technical Changes` as an exact name/version plus plain capability. If absent, do not add it. Ask the human through `docs/INBOX.md`, update the issue after approval, then resume.

The reviewer diffs manifest/config changes against that section. An unapproved addition is blocking. No decision record is required or created.
