# Contributing to GROMACS MD Protocol

Thank you for your interest in improving this protocol! 🎉

This document describes how to contribute bug fixes, documentation improvements,
script enhancements, and new MDP templates.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Style Guidelines](#style-guidelines)
- [What to Contribute](#what-to-contribute)
- [Citation Requirement](#citation-requirement)

---

## Code of Conduct

Please be respectful and constructive in all interactions.  
This is an academic project — collaborate as you would with colleagues.

---

## Reporting Bugs

Before opening an issue, please:

1. Check [docs/09_TROUBLESHOOTING.md](docs/09_TROUBLESHOOTING.md) and [docs/10_FAQ.md](docs/10_FAQ.md).
2. Search existing issues to avoid duplicates.

When filing a bug, include:

- **GROMACS version** (`gmx --version`)
- **OS and GPU** (`uname -a`, `nvidia-smi`)
- **The script that failed** and the exact error message
- **Your `config.env` settings** (remove any personal paths)

---

## Suggesting Enhancements

Open a GitHub Issue with the label `enhancement`. Describe:

- What the enhancement does
- Why it is useful for MD practitioners
- Any references (papers, tutorials) if applicable

---

## Submitting a Pull Request

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b fix/describe-your-fix
   ```

2. **Make focused changes** — one topic per PR.

3. **Test your changes** on a real GROMACS installation when possible.

4. **Update documentation** — if you change a script's behaviour, update the
   corresponding `docs/` file.

5. **Open the PR** with a clear title and description referencing any related issue.

---

## Style Guidelines

### Bash scripts

- Use `set -euo pipefail` at the top of every script.
- Log with timestamps: `log() { echo "[$(date '+%H:%M:%S')] $*"; }`
- Validate all input files before processing.
- Prefer long-form flags (`--version` not `-v`) for readability.
- Add a header comment block explaining inputs and outputs.

### MDP files

- Comment every non-obvious parameter.
- Group parameters logically (run control, output, neighbour search, etc.).
- State units in comments (`; ps`, `; nm`, `; K`).

### Documentation

- Use clear, simple English — many users are non-native speakers.
- Include concrete commands, not just descriptions.
- Link to the relevant script and docs section when cross-referencing.

### Commit messages

Use the imperative mood and keep the first line ≤ 72 characters:

```
Fix NVT script to handle custom GEN_SEED values
Add NPT pressure-coupling explanation to docs/06_NPT.md
Update slurm template for SLURM 23.x partition syntax
```

---

## What to Contribute

Most-wanted contributions:

| Area | Examples |
|---|---|
| **Additional analysis scripts** | MM-PBSA, RMSD clustering, contact maps |
| **Additional MDP templates** | Membrane systems, enhanced sampling (REST2, metadynamics) |
| **Force field support** | AMBER, GROMOS, OPLS-AA workflows |
| **Documentation fixes** | Typos, unclear steps, outdated commands |
| **HPC templates** | PBS/Torque, LSF, SGE job scripts |
| **Error handling** | Better error messages, input validation |

---

## Citation Requirement

All contributors must acknowledge that any use of this repository (including
derived contributions) requires citation per the [README citation section](README.md#-citation-mandatory).

---

*Thank you for helping make this protocol better for the community!*
