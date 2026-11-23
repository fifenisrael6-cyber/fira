# FIRA Cloud VM architecture

## Objective

Use a cloud VM as a controlled execution worker for expensive, repeatable engineering tasks. The FIRA Android app remains the command and results interface; GitHub remains the source of truth for code, review, CI history, and build artifacts.

## Components

1. **FIRA Android client** — submits a task request to the FIRA engine and displays task status, logs, reports, and artifact links.
2. **FIRA engine/API** — authenticates the user, validates a fixed task type and repository scope, records a job, and returns a job identifier. It must never accept arbitrary shell commands from the mobile client.
3. **Job coordinator** — dispatches only approved task types. A later implementation can use a durable queue; the first integration uses GitHub Actions `workflow_dispatch`.
4. **Ephemeral cloud worker** — a Linux x64 VM created for one job, registered as a GitHub Actions self-hosted runner with labels `self-hosted, linux, x64, fira-cloud`, then destroyed and its temporary disk discarded after the job.
5. **GitHub** — stores source code, workflow definitions, PRs, logs, and time-limited build artifacts.

## Initial GitHub integration

The workflow `.github/workflows/fira-cloud-runner.yml` is manual-only and is intentionally restricted to the protected `main` branch. It supports a small allowlist of fixed tasks: Python tests, Android release build, or full validation. It does not accept shell commands, target addresses, scripts, or arbitrary workflow references.

The job targets a self-hosted runner labelled `fira-cloud`, requires the GitHub Environment `fira-cloud-approval`, uses read-only repository permissions, checks out only `main`, and uploads build output as a GitHub Actions artifact.

## Required GitHub setup

1. Merge the integration PR into the feature branch, then merge the feature branch into `main` after reviewing all changes.
2. In repository Settings → Environments, create `fira-cloud-approval`. Configure required reviewers if that option is available for the repository plan.
3. In Settings → Actions → Runners, add a Linux x64 self-hosted runner and restrict its runner group to this repository only.
4. Provision the runner as an **ephemeral, single-job** worker. The cloud provisioning controller must create a clean VM, register a short-lived runner, wait for one job, preserve logs externally, then delete the VM and its disk. Do not keep a privileged persistent runner online.
5. Apply a cloud firewall policy: outbound HTTPS to GitHub and required package registries only; no inbound public administration port; no access to production databases, personal devices, or unrelated networks.
6. Run the workflow manually from `main`. It will remain queued until a correctly labelled runner is online.

## Security boundaries

- Never run this self-hosted runner for `pull_request`, `pull_request_target`, forks, or unreviewed branches.
- Never expose cloud credentials, GitHub registration tokens, signing keys, or production secrets to the job.
- Use short-lived runner registration credentials and short-lived cloud identity where supported.
- Keep `GITHUB_TOKEN` read-only. Do not grant repository write or administration permissions to build jobs.
- Do not let FIRA convert user text into shell commands. Use fixed task identifiers and validated parameters only.
- The first version performs software tests and builds only. It does not scan networks, exploit systems, or run penetration tests.
- Defensive security reports should initially be based on supplied code/configuration/logs and approved lab evidence. Any future active lab execution needs a separate isolated sandbox, explicit scope, rate limits, and human approval.

## Future task lifecycle

`submitted → validated → awaiting approval → queued → running → completed/failed → artifact published`

Every job should record a generated job ID, requesting account, repository/ref, fixed task type, timestamps, status, bounded logs, result summary, and artifact expiry. Secrets and sensitive raw logs must not be copied into the report.

## Cost and availability

A self-hosted runner does not incur a GitHub-hosted runner minute charge, but the cloud VM, storage, bandwidth, and log retention may cost money. Stop/delete workers after each job. The Android app should show a clear queued state when no cloud worker is available.
