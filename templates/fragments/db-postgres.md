## The database is PostgreSQL, and every lane gets its own

The test suite reads a single `{{DB_URI_VAR}}` and migrates before every run. **Two things must never share a database: a lane and the human's development environment, or two lanes with each other.** The second produces flaky tests rather than a visible collision; the first quietly rewrites the state the human is working against.

Provision for a single serial lane too. One issue at a time is not a reason to run the gate against the development database — it is only a reason there is no second lane to collide with.

**Name the lane database in `[a-z0-9_]` only.** Branch slugs are usually dashed (`ord26-checkout-simplify`), and a dash in a PostgreSQL identifier is a trap rather than an error: `createdb` and `dropdb` quote for you, so provisioning and teardown succeed — but any hand-written statement fails, and `DROP DATABASE {{LANE_PREFIX}}ord26-checkout-simplify` is a syntax error at the dash. **Replace every non-alphanumeric character in the slug with `_` when you build the database name**, and keep the dashed form for the branch and worktree, where it is fine. If you ever do write raw SQL against one of these, double-quote the name.

**Provision before spawning the implementer:**

```
SLUG=<issue-slug>                          # dashed, e.g. ord26-checkout-simplify
DB_SLUG="${SLUG//[^a-zA-Z0-9]/_}"          # underscored, for the database name only

git worktree add -b "$SLUG" {{WORKTREE_DIR}}/"$SLUG" {{MAIN_BRANCH}}
createdb "{{LANE_PREFIX}}$DB_SLUG"

# The lane has no .env — create it. Never edit the repo root's.
cp .env {{WORKTREE_DIR}}/"$SLUG"/.env
sed -i '' "s|/{{DEV_DB}}\$|/{{LANE_PREFIX}}$DB_SLUG|" {{WORKTREE_DIR}}/"$SLUG"/.env
```

Then, inside the worktree, install dependencies and run whatever generation step the build needs — a fresh worktree shares neither `node_modules` nor build output with the parent, and both failures read as code errors when they are not.

An empty database is the correct starting state, not a problem: the migration step builds the schema from the committed migrations before the tests run.

**At close, drop every database the lane created.** A test task that derives its own throwaway database leaves two behind, not one — check for a `_test` sibling.

**Drop only a database whose name begins `{{LANE_PREFIX}}`. Never drop anything else, for any reason.** Read the lane's `.env` and check the name before dropping; do not assume the lane is on the database you provisioned. If the name does not match that prefix, the lane was never isolated — leave the database alone and say so.

**Never point a lane at `{{DEV_DB}}`.** That is the human's development database; a lane that migrates it has changed the state the human is working against, and that damage is not self-healing.

If `createdb` is unavailable, do not improvise: pair a stateless issue with a stateful one so a single lane touches the database, or run serially.
