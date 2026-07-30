4. **Redo generated artifacts and migrations — do not merge them.** Each lane generated against the pre-merge state, so the second one may now assume a shape that no longer exists. After resolving conflicts:

   ```
   {{CODEGEN_CMD}}
   ```

   Generated paths (`{{GENERATED_PATHS}}`) are never hand-merged. If the lane's own migration fails against the merged schema, delete it and regenerate.

   **Regenerate and install on `{{MAIN_BRANCH}}` BEFORE running its gate,** too. This is the single most common cause of a red integration branch straight after a clean fast-forward, and it is never a real defect:

   ```
   <install dependencies>
   {{CODEGEN_CMD}}
   ```

   The cause is that generated files are untracked, and a merge cannot update them — so any slice that changed a schema leaves `{{MAIN_BRANCH}}`'s generated output stale, and any slice that added a dependency leaves it uninstalled. In both cases the first gate command fails on it. A red `{{MAIN_BRANCH}}` you caused by skipping this is indistinguishable at a glance from a red one caused by a bad merge, which is the real cost.

4b. **A merged migration is not an applied migration. Apply it, or the human's environment is broken.** The lane ran its migration against its own database, so the gate passes and `{{MAIN_BRANCH}}` is green — while the human's development database still has the old schema. The merged code writes the new column; every request touching it fails.

   After the merge is proven, if the slice added a migration:

   ```
   {{MIGRATE_STATUS_CMD}}
   {{MIGRATE_CMD}}
   ```

   Applying a forward migration to the development database is **allowed and required** — it is additive forward motion, not a reset. Never drop or reset that database.

   If a migration is _not_ purely additive — a drop, a rename, a backfill, anything that could lose the human's data — **do not run it. Escalate to the human with the migration's contents.**

   Either way, **say in the cycle report that a migration was applied and to which database.** A schema change the human learns about from a runtime error is a pipeline failure even when every gate was green.

