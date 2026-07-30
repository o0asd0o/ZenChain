## The database is SQLite, and every lane gets its own file

The test suite reads a single `{{DB_URI_VAR}}`, and the migration step runs before every test run. **Two things must never share a database file: a lane and the human's development environment, or two lanes with each other.** The second produces flaky tests rather than a visible collision; the first quietly rewrites the state the human is working against.

SQLite makes isolation cheap — it is a path, and there is nothing to provision:

```
git worktree add -b <branch> {{WORKTREE_DIR}}/<slug> {{MAIN_BRANCH}}

# The lane has no .env — create it. Never edit the repo root's.
cp .env {{WORKTREE_DIR}}/<slug>/.env
sed -i '' 's|{{DEV_DB}}|{{LANE_PREFIX}}<slug>.db|' {{WORKTREE_DIR}}/<slug>/.env
```

Do this for a single serial lane too. One issue at a time is not a reason to run the gate against the development database — it is only a reason there is no second lane to collide with.

Then, inside the worktree, install dependencies and run whatever generation step the build needs — a fresh worktree shares neither `node_modules` nor build output with the parent, and both failures read as code errors when they are not.

A missing file is the correct starting state, not a problem: the migration step creates it and builds the schema from the committed migrations before the tests run. Do not pre-create it, and do not copy the development database in — a lane that starts from a copy of real data is testing against state no migration produced.

**At close, delete every file the lane created.** SQLite leaves siblings: `-wal` and `-shm` alongside the database, and a separate file if the test task derives its own throwaway database. Check for all of them.

**Delete only a file whose path begins `{{LANE_PREFIX}}`. Never delete anything else, for any reason.** Read the lane's `.env` and check the path before deleting; do not assume the lane is on the file you configured. If the path does not match that prefix, the lane was never isolated — leave the file alone and say so.

**Never point a lane at `{{DEV_DB}}`.** That is the human's development database; a lane that migrates it has changed the state the human is working against, and that damage is not self-healing. This is a sharper risk on SQLite than on a server engine: the target is a relative path, so a lane whose `.env` edit silently failed falls back to the development file rather than failing to connect. **Verify the lane's resolved path before spawning the implementer** — the failure is quiet, and quiet is what makes it expensive.

**One writer at a time.** SQLite serialises writes, so tests inside a lane that expect real write concurrency will not behave as they would on a server engine. Enable WAL if the project does not already, and treat a concurrency test that only passes on SQLite as unproven rather than green — that judgement goes to the `decider`, whose default on "close enough" for a concurrency test is no.
