# Frequently Asked Questions (FAQ)

Answers to the most common questions about running this protocol.

> Also see [docs/09_TROUBLESHOOTING.md](09_TROUBLESHOOTING.md) for error-specific fixes.

---

## Table of Contents

- [General](#general)
- [Installation](#installation)
- [Input Files](#input-files)
- [Topology (Step 01)](#topology-step-01)
- [Solvation (Step 02)](#solvation-step-02)
- [Energy Minimisation (Step 03)](#energy-minimisation-step-03)
- [NVT / NPT (Steps 04–05)](#nvt--npt-steps-0405)
- [Production MD (Step 06)](#production-md-step-06)
- [Analysis (Step 07)](#analysis-step-07)
- [HPC / SLURM](#hpc--slurm)
- [Citation](#citation)

---

## General

### Q: How long does the full protocol take?

| Stage | Typical time (V100S GPU) |
|---|---|
| Energy minimisation | 2–5 min |
| NVT equilibration (100 ps) | 5–10 min |
| NPT equilibration (100 ps) | 5–10 min |
| Production MD (100 ns) | 4–10 hours |
| Analysis | 5–15 min |

Actual time depends on system size, GPU model, and number of CPU threads.

### Q: Can I simulate without a GPU?

Yes. Remove `-gpu_id` flags from the `gmx mdrun` calls in the scripts,
or set `GPU_ID=` (empty) in `config.env`. CPU-only runs will be much slower —
a 100 ns simulation may take days instead of hours.

### Q: What system sizes are supported?

The protocol works for any system that fits in RAM and GPU memory.
Typical protein–ligand complexes (~50 000–150 000 atoms after solvation) run
well on a single 16–40 GB GPU. Larger systems may require multi-GPU or HPC.

### Q: Can I change the simulation length?

Yes. Edit `mdp/md_100ns.mdp`:
```
; nsteps × dt = simulation time
; 50 000 000 steps × 0.002 ps = 100 ns
nsteps = 50000000
dt     = 0.002        ; ps
```
For 200 ns: set `nsteps = 100000000`.

---

## Installation

### Q: Which installation method should I use?

| Situation | Recommended method |
|---|---|
| Personal laptop / workstation | Conda / Mamba |
| University HPC cluster | Apptainer / Singularity or module load |
| Quick test (Ubuntu) | `sudo apt install gromacs` |

See [INSTALLATION.md](../INSTALLATION.md) for full instructions.

### Q: How do I check if GROMACS is using my GPU?

```bash
gmx mdrun --version 2>&1 | grep -i cuda
# Should show: CUDA support: enabled

# During a run, check gmx mdrun output for:
# "On host ... using 1 GPU"
```

### Q: I get "CUDA not found" even though nvidia-smi works.

Your conda GROMACS build may not include CUDA. Try:
```bash
mamba install -c conda-forge gromacs=2024.3 cudatoolkit=12.2
```
Make sure `cudatoolkit` version matches your NVIDIA driver.

---

## Input Files

### Q: My protein has multiple chains. What do I do?

Keep all chains in `protein_clean.pdb`. GROMACS `pdb2gmx` handles multi-chain
proteins automatically — it adds a `TER` record between chains and creates
separate molecule entries in the topology.

### Q: I only have a `.mol2` file for my ligand, not a CHARMM-GUI export.

You need to parameterise the ligand first. Options:
1. **CHARMM-GUI** (recommended): upload the `.mol2` and download the GROMACS files
2. **CGenFF server**: https://cgenff.umaryland.edu/ (requires registration)
3. **LigParGen** (for OPLS-AA): http://zarbi.chem.yale.edu/ligpargen/

### Q: What is the LIGAND_MOLNAME variable?

It must match the name in the `[ moleculetype ]` section of your `lig.itp`:
```
[ moleculetype ]
; Name            nrexcl
LIG               3      ← this is the name
```
Set `LIGAND_MOLNAME=LIG` (or whatever it says) in `config.env`.

---

## Topology (Step 01)

### Q: `pdb2gmx` asks about histidine protonation state — what do I choose?

The script uses `printf "1\n" | gmx pdb2gmx` to auto-select option 1 (HISD)
for all histidines. If your protein has histidines that coordinate metals
or are in specific protonation states, you need to:
1. Run `pdb2gmx` interactively (remove the `printf | ` part)
2. Answer the prompts based on your biological knowledge
3. Alternatively, rename histidines in the PDB to `HISD`, `HISE`, or `HISH`
   before running the script

### Q: I get "Fatal error: atom X in residue Y not found in rtp"

This means pdb2gmx doesn't recognise an atom in your PDB. Common causes:
- Non-standard residue names (e.g., selenomethionine `MSE`)
- Modified residues from crystallisation
- Incorrect atom names (e.g., `1HB` instead of `HB1`)

Fix: clean the PDB more carefully in PyMOL, or use `pdbfixer` with
`--add-atoms=heavy`.

---

## Solvation (Step 02)

### Q: How big should the water box be?

The default (1.0 nm minimum distance from solute to box edge, dodecahedron)
is sufficient for most systems. For proteins with large conformational changes
or for REMD simulations, use 1.2–1.5 nm.

### Q: Can I use a different water model?

Yes. Change `WATER_MODEL` in `config.env`. Options: `tip3p`, `tip4p`, `spc`,
`spce`. You must also use a force field compatible with your water model.

---

## Energy Minimisation (Step 03)

### Q: EM converges very slowly (takes hundreds of thousands of steps).

This usually means there are severe steric clashes in the initial structure.
Try:
1. Checking the protein–ligand docking pose (are atoms overlapping?)
2. Cleaning the PDB more thoroughly (remove all non-protein atoms first)
3. Reducing `emtol` in `mdp/em.mdp` temporarily to 100 kJ/mol/nm

### Q: EM fails with "step size is zero" or "LINCS warning"

The starting structure has overlapping atoms. Inspect with PyMOL:
```bash
# Open complex.gro in PyMOL to visualise clashes
pymol work/01_topology/complex.gro
show sticks, all
```

---

## NVT / NPT (Steps 04–05)

### Q: What is the difference between NVT and NPT?

| Ensemble | Fixed | Used for |
|---|---|---|
| NVT | N, V, T | Temperature equilibration |
| NPT | N, P, T | Pressure equilibration |

NVT first heats and stabilises temperature. NPT then equilibrates pressure.
Both use position restraints on the protein heavy atoms during equilibration.

### Q: Can I increase equilibration time?

Yes. Edit `mdp/nvt.mdp` and `mdp/npt.mdp`:
```
; 50000 steps × 0.002 ps = 100 ps (current)
; For 1 ns equilibration:
nsteps = 500000
```

---

## Production MD (Step 06)

### Q: How do I check if the simulation is running correctly?

```bash
# Watch the log file in real time
tail -f work/06_md/md.log

# Check energy conservation (look for potential energy ~−XXXXX kJ/mol)
gmx energy -f work/06_md/md.edr -o potential.xvg
```

### Q: What are reasonable RMSD values for a well-behaved simulation?

| System component | Acceptable RMSD |
|---|---|
| Protein backbone | < 3 Å (< 0.3 nm) typically |
| Ligand | < 2 Å from initial position |

Higher values may indicate instability — check the trajectory visually.

---

## Analysis (Step 07)

### Q: What analyses does `07_analysis.sh` run?

| Analysis | Output file | What it shows |
|---|---|---|
| RMSD (backbone) | `results/rmsd_backbone.xvg` | Structural stability over time |
| RMSF (per residue) | `results/rmsf_residue.xvg` | Flexibility of each residue |
| Radius of gyration | `results/gyrate.xvg` | Compactness of the protein |
| Hydrogen bonds | `results/hbond_count.xvg` | Protein–ligand H-bond count |
| SASA | `results/sasa.xvg` | Solvent-accessible surface area |

### Q: How do I visualise the trajectory?

```bash
# In VMD:
vmd work/01_topology/complex.gro work/06_md/md.xtc

# In PyMOL:
pymol work/01_topology/complex.gro work/06_md/md.xtc
```

### Q: How do I do MM-PBSA binding free energy calculations?

This protocol does not include MM-PBSA, but you can use:
- `gmx_MMPBSA`: https://valdes-tresanco-ms.github.io/gmx_MMPBSA/
- `g_mmpbsa`: older tool, check compatibility

---

## HPC / SLURM

### Q: How do I choose the right number of threads?

A good starting point:
```
NTMPI = 1 (one MPI rank per GPU)
NTOMP = number of CPU cores assigned to the job / NTMPI
```
For a node with 1 GPU and 16 cores: `NTMPI=1`, `NTOMP=16`.

### Q: My job is killed before it completes.

Increase the `#SBATCH --time` limit in `templates/slurm/gmx_gpu.slurm`.
For 100 ns on a V100S, request at least 12 hours to be safe.

### Q: Can I continue an interrupted simulation?

Yes! GROMACS writes checkpoint files (`.cpt`) regularly:
```bash
gmx mdrun -v -deffnm work/06_md/md -cpi work/06_md/md.cpt -noappend
```
The `-noappend` flag starts a new output file series (`md.part0002.*`).

---

## Citation

### Q: Do I really have to cite this repository?

**Yes.** Citation is a condition of use. See the
[Citation section in README.md](../README.md#-citation-mandatory) for the
required formats (APA, BibTeX, IEEE).

### Q: I used only one script — do I still need to cite?

Yes. Any use — even adapting a single script — requires citation.

---

*Have a question not answered here? Open a GitHub Issue!*
