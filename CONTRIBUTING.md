# Contributing Guidelines

## Umbrella Project

OpenEBS is an `Umbrella Project` whose governance and policies are defined in the [community](https://github.com/openebs/community/) repository.
These policies are applicable to every sub-project, repository and file existing within the [OpenEBS GitHub organization](https://github.com/openebs/).

This project follows the [OpenEBS Contributor Guidelines](https://github.com/openebs/community/blob/HEAD/CONTRIBUTING.md).

## Local Development

The Rust workspace in this repository depends on the `mayastor` submodule and nested submodules under it.
Before running local `cargo` builds or tests, initialize submodules:

```bash
git submodule update --init --recursive
```

For a fresh clone, you can fetch everything in one step:

```bash
git clone --recurse-submodules https://github.com/openebs/openebs.git
```

There is also a helper script for existing checkouts:

```bash
./scripts/nix/git-submodule-init.sh
```
