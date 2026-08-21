# Triage labels

The skills speak in terms of five canonical triage roles. This file maps those roles to this repo's GitHub labels.

| Canonical role    | Label             | Meaning                                                        |
| ----------------- | ----------------- | -------------------------------------------------------------- |
| `needs-triage`    | `needs-triage`    | Someone needs to evaluate this issue                           |
| `needs-info`      | `needs-info`      | Waiting on the reporter for more information                   |
| `ready-for-agent` | `ready-for-agent` | Fully specified, ready for an unattended agent                  |
| `ready-for-human` | `ready-for-human` | Not yet built; needs a human to implement it                    |
| `wontfix`         | `wontfix`         | Will not be actioned                                           |

Closing state is GitHub's own: an issue that merged with a green gate is **closed as completed**, not labelled — `gh issue close <N> --reason completed`. That is the one advantage a remote tracker has here: it has a real closed state, so there is no `done` label, and none is created. Where the orchestrator says "mark the issue done", on this tracker that means close it.

Create the labels once:

```bash
for l in needs-triage needs-info ready-for-agent ready-for-human wontfix; do
  gh label create "$l" --force
done
```

## `ready-for-human` does not mean finished

It means an agent must not attempt this. Never use it on a successful close — closing the issue is how the pipeline says done. Mixing the two makes finished and blocked work indistinguishable in a label filter, which is the one thing the filter exists for.

A blocking implementation question carries `needs-info` and keeps the issue open. It lives in `docs/INBOX.md` until the human answer updates the issue packet. A closed issue may retain a non-blocking human-eyes observation, but no unresolved contract choice.
