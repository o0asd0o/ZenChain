# Triage labels

The skills speak in terms of five canonical triage roles. This file maps those roles to this repo's GitHub labels.

| Canonical role    | Label             | Meaning                                                        |
| ----------------- | ----------------- | -------------------------------------------------------------- |
| `needs-triage`    | `needs-triage`    | Someone needs to evaluate this issue                           |
| `needs-info`      | `needs-info`      | Waiting on the reporter for more information                   |
| `ready-for-agent` | `ready-for-agent` | Fully specified, ready for an unattended agent                  |
| `ready-for-human` | `ready-for-human` | Not yet built; needs a human to implement it                    |
| `wontfix`         | `wontfix`         | Will not be actioned                                           |

Closing state is GitHub's own: an issue that merged with a green gate is **closed as completed**, not labelled. That is the one advantage a remote tracker has here — it has a real closed state, so nothing needs a `done` label.

Create the labels once:

```bash
for l in needs-triage needs-info ready-for-agent ready-for-human wontfix; do
  gh label create "$l" --force
done
```

## `ready-for-human` does not mean finished

It means an agent must not attempt this. Never use it on a successful close — closing the issue is how the pipeline says done. Mixing the two makes finished and blocked work indistinguishable in a label filter, which is the one thing the filter exists for.

A closed issue may still carry open questions for a person — an unverified figure, a flagged design conflict. Those go in a closing comment and surface at the PRD checkpoint. They do not reopen the issue, because the _work_ is finished; what remains is a decision, not an implementation.
