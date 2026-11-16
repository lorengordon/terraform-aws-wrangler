# Agent Instructions

Before starting any task in this repository:

1. Run `make agents/sync`. It writes the shared Plus3 IT instructions for this repository's tardigrade-ci version to `.agents/plus3it/AGENTS.md`.
2. Read `.agents/plus3it/AGENTS.md` and follow it together with this file. If the sync fails, tell the user, and don't guess the conventions.

These rules always apply, even without the shared instructions:

- Don't push, open pull requests, publish releases, or apply infrastructure changes unless the user asks. List those steps for a person in your final report.
- Don't edit files under `.agents/plus3it/`; they are generated and overwritten by the sync.

@.agents/plus3it/AGENTS.md

## Repository-specific

### Purpose

This module collects files from source URIs and stores them in an S3 bucket. The main input is `uri_map`, a map of source URI to S3 key path, with `bucket_name` and an optional `prefix`. It downloads each file through the `terraform-external-file-cache` module, uploads it with `aws_s3_object`, and by default (`create_hashes`) also uploads a `.SHA512` file next to it. The outputs are `files` and `hashes`, maps of S3 object ID to source hash.

### Module-specific files

- `Dockerfile`: builds on the tardigrade-ci image and installs `requirements.txt`, so those packages are in the image. The tardigrade-ci `docker/run` target, which the shared lint workflow calls, builds this image when it is not already present.
- `requirements.txt`: the Python packages that the `Dockerfile` installs.
- `tests/`: one directory per test case (`noop`, `no_hashes`, `uri_map`, `s3_sync`). The `no_hashes`, `uri_map` and `s3_sync` cases each have a `prereq/` directory with its own Terraform code.

### Deviations from the terraform-module profile

- There is no `CHANGELOG.md`, so skip the changelog step. To release, run `make bumpversion/patch` (or `minor` or `major`). It updates `current_version` in `.bumpversion.cfg` and makes its own commit, with no tag (`tag = False`). When that change reaches `main` (or `master`), `.github/workflows/release.yml` runs, because it triggers on pushes that change `.bumpversion.cfg`. It also runs on demand. The shared release workflow lints and tests, then creates a GitHub Release with generated notes if `current_version` differs from the latest git tag.
- The Makefile sets `TF_VAR_s3_endpoint_url` for the `terraform/pytest` target only, and only when `PYTEST_ARGS` does not contain `--nomock`. The value is `http://<host>:4615`, where the host is `MOCKSTACK_HOST` if set (as in the mockstack container) and `localhost` otherwise. It matters only for `tests/s3_sync`, the one test that declares an `s3_endpoint_url` variable and passes it to the module, so that `s3://` source URIs are read from the mock S3 service. With `--nomock`, the variable is not set and the test uses real AWS.
