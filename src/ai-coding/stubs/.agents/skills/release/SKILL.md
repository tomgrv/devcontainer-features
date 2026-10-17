---
name: release
description: >
  Trigger the Release Prod workflow, check its status 5 minutes later, and
  archive this session if it succeeded. Use when the user says "/release",
  "run the release workflow", or "release and archive".
---

## Steps

1. Make sure everything is committed and pushed — archiving releases the container.
2. Trigger `release-prod.yml` on `develop` with `actions_run_trigger` (`run_workflow`). Pass `dry_run` only if the user asked for a dry run.
3. Find the run it started (`actions_list`, newest run of that workflow) and note its id.
4. Wait 5 minutes without blocking the shell — no foreground `sleep`; use `Monitor` with an until-loop, or the session's wake-up mechanism. One wait, no polling loop.
5. Read the run's status and conclusion (`actions_get`).
6. `success` → archive this session: `get_session` (no id) for the session id, then `archive_session`.
7. Anything else → report it and keep the session open:
   - `in_progress`/`queued`: say so, ask whether to wait again.
   - `failure`/`cancelled`: quote the failing job and its error from `get_job_logs`.

## Boundaries

Never archive on anything but a `success` conclusion. Never re-trigger the workflow to get past a failure — report it. Never push or rewrite history to make the release pass.
