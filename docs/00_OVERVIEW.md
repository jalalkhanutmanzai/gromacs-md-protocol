# Protocol Overview

This repository implements a **complete, reproducible GROMACS molecular
dynamics protocol** for protein–ligand complexes.

## Workflow summary

```
Input files (protein PDB + CHARMM-GUI ligand files)
        │
        ▼
01  Build topology          pdb2gmx + merge ligand ITP
        │
        ▼
02  Solvate + add ions      editconf → solvate → genion
        │
        ▼
03  Energy minimisation     grompp + mdrun (steep, ~5 000 steps)
        │
        ▼
04  NVT equilibration       100 ps, 300 K, velocity-rescaling
        │
        ▼
05  NPT equilibration       100 ps, 1 bar, Parrinello-Rahman
        │
        ▼
06  Production MD           100 ns (50 000 000 steps × 2 fs)
        │
        ▼
07  Analysis                RMSD, RMSF, Rg, H-bonds, SASA
```

## Estimated run time (V100S GPU)

| Stage | Wall time |
|---|---|
| Energy minimisation | 2–5 min |
| NVT equilibration | 5–15 min |
| NPT equilibration | 5–15 min |
| Production 100 ns | 4–8 h |
| Analysis | 10–30 min |

## Force field

- Protein: **CHARMM36m**
- Ligand: **CGenFF** (via CHARMM-GUI parameterisation)
- Water: **TIP3P**

## Key software

- GROMACS 2024.3 (CUDA build)
- Optional: VMD / PyMOL for visualisation
- Optional: Python + matplotlib for plotting analysis output

## Documentation map

| File | Contents |
|---|---|
| docs/01_PREREQUISITES.md | Software, input files, directory setup |
| docs/02_TOPOLOGY.md | pdb2gmx, ligand ITP merging |
| docs/03_SOLVATE_IONS.md | editconf, solvate, genion |
| docs/04_EM.md | grompp, mdrun energy minimisation |
| docs/05_NVT.md | NVT equilibration |
| docs/06_NPT.md | NPT equilibration |
| docs/07_PRODUCTION_MD.md | Production run, SLURM submission |
| docs/08_ANALYSIS.md | RMSD, RMSF, Rg, H-bonds, SASA |
| docs/09_TROUBLESHOOTING.md | Common errors and fixes |

