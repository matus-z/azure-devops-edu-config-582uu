# Kalkulačka poistenia — config repo

The configuration side of the workshop setup (`kalkulacka-config`). It holds the
pipeline, the version pointer and the release documentation. The application
code lives in the vendor repo (`kalkulacka-dodavatel`) and is never edited here.

## Project structure

| Path                    | Responsibility                                                     |
| ----------------------- | ------------------------------------------------------------------ |
| `azure-pipelines.yml`   | The full pipeline: Build → Verify → Publish → Staging → Production. |
| `version.json`          | Which vendor tag gets built — `{ "version": "v1.2.1" }`.            |
| `docs/CHANGELOG.md`     | Release notes; must mention the version being deployed.            |
| `docs/popis-zmeny.md`   | Description of the change for the approver.                        |

## Releasing a version

Editing `version.json` *is* the release. The pipeline reads the version at run
time and clones the vendor repo at that tag, so bumping a version never means
editing the pipeline:

```json
{ "version": "v1.2.1" }
```

Then update `docs/CHANGELOG.md` so it names the same version — the `docs` job
fails the build if it doesn't.

## Pipeline stages

| Stage        | What it does                                                          |
| ------------ | --------------------------------------------------------------------- |
| `Build`      | Reads `version.json`, clones the vendor tag, produces `dist/`.        |
| `Verify`     | Two parallel jobs: `node --test` on the vendor tests, and the docs check. |
| `Publish`    | Publishes the verified `app` artifact — nothing unverified is published. |
| `Staging`    | Deployment job on the `staging` environment.                          |
| `Production` | Deployment job on the `production` environment.                       |

Approvals and checks are **not** in this file. They are configured on the
`staging` and `production` environments in Azure DevOps, which is what makes
the run pause for an approver.

`trigger: none` — runs are started by hand, so it is always visible who started one.

## Not in this repo yet

`version.json` and `docs/` are referenced by the pipeline but not committed. A
run fails at the first step until `version.json` exists, and at the `docs` job
until both documents do.
