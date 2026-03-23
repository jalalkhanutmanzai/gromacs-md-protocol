# Changelog

All notable changes to the GROMACS Protein–Ligand MD Protocol are documented here.

This project follows [Semantic Versioning](https://semver.org/) conventions
(`MAJOR.MINOR.PATCH`). Since this is a protocol repository, versions track
significant workflow and documentation changes.

---

## [Unreleased]

### Added
- `CONTRIBUTING.md` — contribution guidelines for bug reports and PRs
- `environment.yml` — pinned conda environment for exact reproducibility
- `Makefile` — convenience targets (`make all`, `make check`, `make em`, …)
- `input/README.md` — step-by-step guide for preparing input files
- `docs/10_FAQ.md` — comprehensive FAQ covering all pipeline stages
- `CHANGELOG.md` — this file

### Changed
- `README.md` — full overhaul with badges, table of contents, visual workflow
  diagram, and improved formatting throughout
- Team member name corrected: **Tayyaba Ayaz → Tayyaba Riyaz**
- Title updated: **Mr. Jalal Khan Utman** (with honorific)
- Citation section prominently restructured with APA, BibTeX, and IEEE formats

### Fixed
- n/a

---

## [1.0.0] — 2024-01-01

### Added
- Initial release of the complete GROMACS protein–ligand MD protocol
- Nine numbered step scripts (`01_prepare_topology.sh` through `07_analysis.sh`)
- `run_complete_workflow.sh` — end-to-end pipeline runner
- Four MDP parameter files: `em.mdp`, `nvt.mdp`, `npt.mdp`, `md_100ns.mdp`
- Comprehensive documentation in `docs/` (00_OVERVIEW through 09_TROUBLESHOOTING)
- SLURM GPU job template (`templates/slurm/gmx_gpu.slurm`)
- Shared configuration via `config/config.env.example`
- `INSTALLATION.md` covering apt, conda, and Apptainer install methods
- `QUICKSTART.md` — minimal steps to start a simulation
- `CITATION.cff` — machine-readable citation metadata
- `LICENSE` — MIT

---

[Unreleased]: https://github.com/jalalkhanutmanzai/gromacs-md-protocol/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/jalalkhanutmanzai/gromacs-md-protocol/releases/tag/v1.0.0
