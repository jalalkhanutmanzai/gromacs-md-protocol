# 09 — Troubleshooting

This page covers the most common GROMACS errors encountered when running a
protein–ligand MD protocol, with step-by-step fixes.

---

## Table of contents

1. [Missing include / force-field files](#1-missing-include--force-field-files)
2. [LINCS warnings](#2-lincs-warnings)
3. [PME / electrostatics instability](#3-pme--electrostatics-instability)
4. [NaN / Inf energy — simulation explodes](#4-nan--inf-energy--simulation-explodes)
5. [Segmentation faults](#5-segmentation-faults)
6. [CUDA / GPU errors](#6-cuda--gpu-errors)
7. [grompp: too many warnings](#7-grompp-too-many-warnings)
8. [Topology mismatch (atom count)](#8-topology-mismatch-atom-count)
9. [Position-restraint file not found](#9-position-restraint-file-not-found)
10. [Checkpoint / restart issues](#10-checkpoint--restart-issues)

---

## 1. Missing include / force-field files

**Error:**
```
Fatal error: Cannot find file 'charmm36-jul2022.ff/forcefield.itp'
```

**Cause:** GROMACS cannot locate the force-field directory.

**Fix:**
```bash
# Check which force fields are available
gmx pdb2gmx -h 2>&1 | grep "Force fields"

# Or list the forcefield directories in your GROMACS data path
ls $(gmx -h 2>&1 | grep "^Data prefix" | awk '{print $NF}')/top/
```

If using a conda or container install, set `GMXLIB` to point to the right directory:

```bash
export GMXLIB=/path/to/gromacs/share/gromacs/top
```

---

## 2. LINCS warnings

**Warning:**
```
WARNING: 5 of the 5000 update groups in Coordinate Lincs ...
```

**Cause:** LINCS (Linear Constraint Solver) cannot satisfy bond-length
constraints, usually because atoms have moved too far in one step.

**Common fixes:**

| Situation | Fix |
|---|---|
| During EM | Reduce `emstep` in `em.mdp` (e.g. from `0.01` to `0.001`) |
| During NVT/NPT | Reduce `dt` from `0.002` to `0.001` temporarily |
| Persistent | Check topology for unrealistic bonds; visualise the last frame |
| Severe (crash) | Start from a better-minimised structure; increase EM steps |

---

## 3. PME / electrostatics instability

**Error:**
```
Fatal error: (file src/gromacs/ewald/pme-internal.h, line 74)
PME grid size ... is not supported
```

or

```
Fatal error: The sum of the two largest charge group radii ... exceeds ...
```

**Fixes:**

- Ensure `rcoulomb` = `rlist` in the MDP (for `cutoff-scheme = Verlet`).
- Use a PME grid that is a product of small primes.  
  `fourierspacing = 0.12` usually gives a good grid automatically.
- Increase the box size if the solute is larger than expected.
- For `cutoff-scheme = Verlet`, set `nstlist = 10` or higher.

---

## 4. NaN / Inf energy — simulation explodes

**Error:**
```
Fatal error: Energy is not finite (Inf/NaN) at step 0
```

or the simulation crashes at step 0 with `Potential Energy = -nan`.

**Cause:** Atoms are overlapping (distances → 0), producing infinite forces.

**Fixes:**
1. Ensure you ran energy minimisation and it converged (`Fmax < emtol`).
2. Run with a smaller time step in NVT (`dt = 0.001`) for the first few ps.
3. Check topology: duplicate atoms, wrong charge, missing parameters.
4. Visualise the structure: `vmd work/03_em/em.gro` or use PyMOL.

---

## 5. Segmentation faults

**Error:**
```
Segmentation fault (core dumped)
```

**Possible causes and fixes:**

| Cause | Fix |
|---|---|
| Wrong GROMACS binary for GPU | Use the GPU-enabled build; check `gmx --version | grep CUDA` |
| Incompatible MPI and thread settings | Use `-ntmpi 1` for thread_mpi builds |
| Corrupted TPR file | Re-run `grompp` |
| Memory issue | Reduce `-ntomp`, check available RAM |
| Compiler bug | Try a different GROMACS version or prebuilt container |

---

## 6. CUDA / GPU errors

**Error:**
```
CUDA runtime error ... no kernel image is available
```
or
```
Fatal error: No compatible GPU found
```

**Fixes:**

```bash
# Verify GPU is visible
nvidia-smi

# Verify GROMACS was compiled with CUDA
gmx --version | grep -i cuda

# Run without GPU to test
gmx mdrun -deffnm em -ntmpi 1 -ntomp 4 -nb cpu -pme cpu
```

For architecture mismatch (compute capability), use a prebuilt GROMACS
container from NVIDIA NGC that matches your GPU generation.

---

## 7. grompp: too many warnings

**Error:**
```
Fatal error: There are X warnings and you have set -maxwarn to Y
```

**Fix:** Increase `-maxwarn` in the `grompp` call:

```bash
gmx grompp ... -maxwarn 5
```

Read each warning carefully first.  Warnings about missing charge groups
or partial charges on ligands are common and often safe to ignore.
Warnings about overlapping atoms are serious and must be fixed.

---

## 8. Topology mismatch (atom count)

**Error:**
```
Fatal error: number of atoms in run input file ... does not match ...
```

**Cause:** The `.tpr` and the `.gro` / `.xtc` file have different atom counts.

**Fix:** Re-run `grompp` with the correct input `.gro` file.  
Ensure you are using the right coordinate file for each step (e.g. using
`ions.gro` for EM, `em.gro` for NVT, etc.).

---

## 9. Position-restraint file not found

**Error:**
```
Fatal error: Cannot find file 'posre.itp'
```

**Cause:** The `topol.top` includes `posre.itp` but `grompp` is not run from
the right directory, or `-I` include path is missing.

**Fix:**

```bash
# Run grompp from the topology directory OR add an include path
gmx grompp ... -I work/01_topology/
```

Alternatively, use an absolute path in `topol.top`:

```
#include "/absolute/path/to/posre.itp"
```

---

## 10. Checkpoint / restart issues

**Error:**
```
Fatal error: Checkpoint file is corrupted or not found
```

**Fix:** If the checkpoint is corrupted, restart from the last good checkpoint
or the previous stage's `.gro` file:

```bash
# List checkpoint files
ls -lth work/06_md/*.cpt

# Restart from the backup checkpoint
gmx mdrun -v -deffnm md -cpi md_prev.cpt ...
```

GROMACS keeps `md.cpt` (latest) and `md_prev.cpt` (previous).
If `md.cpt` is corrupted, use `md_prev.cpt`.

---

## Getting more help

- [GROMACS manual](https://manual.gromacs.org/)
- [GROMACS user forum](https://gromacs.bioexcel.eu/)
- [MDTutorials](http://www.mdtutorials.com/gmx/)
- Open an issue in this repository if you find a protocol-specific problem.
