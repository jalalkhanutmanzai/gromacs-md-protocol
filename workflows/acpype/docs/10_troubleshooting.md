# Troubleshooting Guide

This guide covers the most common errors encountered in GROMACS protein-ligand MD simulations, organized by step.

---

## General GROMACS Tips

### Always check the log file first
```bash
tail -100 simulation/em.log
tail -100 simulation/nvt.log
tail -100 simulation/md_0_100.log
```

### Find all warnings and errors
```bash
grep -i "warning\|error\|fatal" simulation/md_0_100.log
```

### Check your topology before running
```bash
gmx grompp -f mdp/em.mdp -c simulation/complex_solv_ions.gro \
           -p simulation/topol.top -o /tmp/test.tpr -maxwarn 5
```

---

## Step 1: Protein Preparation

### Problem: `ligand_raw.pdb` is empty

**Cause:** The ligand HET code doesn't match what's in the PDB file.

**Fix:**
```bash
# Find actual HETATM codes in your PDB
grep "^HETATM" 1IEP.pdb | awk '{print $4}' | sort | uniq
```
Update `LIGAND_ID` in `scripts/01_prepare_protein.sh` to match the exact 3-letter code.

### Problem: Missing residues

**Cause:** Crystal structure has gaps (disordered regions not resolved in X-ray).

**Fix options:**
1. Use a different PDB with fewer missing residues
2. Model missing loops with MODELLER or Swiss-Model
3. Proceed if missing residues are far from the binding site

---

## Step 2: Ligand Topology

### Problem: `antechamber` fails with charge calculation error

**Cause:** AM1-BCC charge calculation can fail for some molecules.

**Fix:**
```bash
# Try RESP charges instead
antechamber -i ligand_raw.pdb -fi pdb -o LIG.mol2 -fo mol2 \
            -c resp -nc 0 -at gaff2

# Or try without specifying charge method (uses default)
antechamber -i ligand_raw.pdb -fi pdb -o LIG.mol2 -fo mol2 \
            -nc 0 -at gaff2
```

### Problem: ACPYPE fails or produces empty `.itp`

**Cause:** Usually related to input file format issues.

**Fix:**
```bash
# Check MOL2 file looks reasonable
head -30 simulation/LIG.mol2

# Try running ACPYPE with more verbose output
acpype -i simulation/LIG.mol2 -b LIG_GMX -c bcc -n 0 -a gaff2 -v 5
```

### Problem: Wrong ligand net charge

**Symptom:** System total charge is not an integer after solvation.

**Fix:** Check the formal charge:
- Look up on PubChem: https://pubchem.ncbi.nlm.nih.gov
- Search by name, look for "Formal Charge" in the Chemical and Physical Properties section
- Then update `LIGAND_CHARGE` in the script

---

## Step 3: Topology Building

### Problem: `Fatal error: Residue XX not found in force field`

**Cause:** Non-standard residue (modified amino acid, cofactor, etc.)

**Fix options:**
1. Remove the non-standard residue if it's not important
2. Rename it to the standard IUPAC name (e.g., `MSE` → `MET`)
3. Parameterize it separately (advanced — similar to ligand parameterization)

### Problem: `Fatal error: charge group X has non-integer charge`

**Cause:** The net charge of a residue group is not an integer.

**Fix:**
```bash
# Check the charge in pdb2gmx output
grep "Total charge" simulation/topol*.itp
```
This usually means a protonation state issue. Check HIS, ASP, GLU at unusual pH.

### Problem: `[ molecules ] not ordered consistently`

**Cause:** Order in `[ molecules ]` doesn't match order of atoms in `.gro` file.

**Fix:** Make sure `topol.top` lists molecules in the same order as `complex.gro`:
1. Protein first
2. Ligand second
3. Water (SOL) third
4. Ions last

---

## Step 4: Solvation and Ions

### Problem: `Fatal: 2 water molecules can not be added`

**Cause:** Box is too small.

**Fix:** Increase the box distance:
```bash
gmx editconf -f complex.gro -o complex_box.gro -c -d 1.5 -bt dodecahedron
```

### Problem: `genion` crashes or can't find `SOL` group

**Fix:**
```bash
# List available groups
gmx make_ndx -f simulation/complex_solv.gro -o /tmp/index.ndx
# Type 'q' to quit — it will show group names
```
Then use the correct group name when running genion.

---

## Step 5: Energy Minimization

### Problem: `Steepest Descents did not converge` / `Stepsize too small`

**Cause:** The system has very severe clashes that the minimizer can't resolve.

**Fix:**
```bash
# Option 1: Loosen the tolerance
# Edit mdp/em.mdp: emtol = 10000 (instead of 1000)

# Option 2: Use more steps
# Edit mdp/em.mdp: nsteps = 100000

# Option 3: Add a preliminary short run with even looser settings
emtol = 50000
nsteps = 10000
```

### Problem: Simulation crashes immediately (segfault, NaN)

**Cause:** Catastrophic atomic overlap — atoms on top of each other.

**Fix:** Visualize `complex_solv_ions.gro` in VMD. Look for atoms in impossible positions. The ligand may be overlapping with the protein.

---

## Step 6-7: Equilibration

### Problem: `Fatal: Group 'Protein_LIG' not found`

**Cause:** GROMACS doesn't have a group with that exact name.

**Fix:**
```bash
# Find your actual group names
echo "q" | gmx make_ndx -f simulation/em.gro
```

Then edit `mdp/nvt.mdp` and `mdp/npt.mdp`:
```ini
tc-grps = Protein Non-Protein   ; Use these instead
```

### Problem: Temperature not reaching 300 K

**Fix:** Check that `ref_t = 300 300` in `nvt.mdp` and that `gen_temp = 300`.

### Problem: System explodes during NPT (atoms fly to infinity)

**Cause:** NVT equilibration was insufficient or the barostat parameters are wrong.

**Fix:**
```bash
# Option 1: Use a gentler barostat first
# In npt.mdp, change:
pcoupl = Berendsen         # gentler than Parrinello-Rahman
tau_p  = 0.5               # shorter coupling

# Option 2: Run longer NVT (200 ps)
# Edit nvt.mdp: nsteps = 100000

# Option 3: Check for unusual atoms in the ligand
```

---

## Step 8: Production MD

### Problem: LINCS warnings / bond length errors

**Symptom:** `WARNING: 1 particles communicated to vsite LINCS`

**Cause:** Forces are too large — usually from a bad geometry.

**Fix:**
```bash
# Option 1: Check last known good configuration
gmx mdrun -v -deffnm md_0_100 -cpi md_0_100_prev.cpt -append

# Option 2: Reduce time step temporarily
# Edit md_100ns.mdp: dt = 0.001  (1 fs instead of 2 fs)
```

### Problem: GPU out of memory

**Fix:**
```bash
# Reduce the GPU workload
gmx mdrun -v -deffnm md_0_100 -gpu_id 0 -ntmpi 1 -ntomp 8 \
          -nb gpu -pme cpu    # Run PME on CPU instead of GPU
```

### Problem: Simulation was killed (HPC time limit)

**Fix:** Always resume from checkpoint:
```bash
gmx mdrun -v -deffnm simulation/md_0_100 \
          -cpi simulation/md_0_100.cpt \
          -append -gpu_id 0 -ntmpi 1
```
The `-append` flag continues the existing `.xtc` and `.edr` files.

---

## Step 9: Analysis

### Problem: `Group not found` in gmx rms / rmsf

**Fix:**
```bash
# Create a custom index file
gmx make_ndx -f simulation/md_0_100.tpr -o simulation/index.ndx
# Use the interactive interface to create Protein+LIG group, etc.
# Then use: -n simulation/index.ndx in analysis commands
```

### Problem: Trajectory shows broken molecules / atoms jumping

**Cause:** Periodic boundary conditions not fixed.

**Fix:** Redo the `trjconv` step with additional `-pbc` options:
```bash
echo "1 0" | gmx trjconv \
    -s simulation/md_0_100.tpr \
    -f simulation/md_0_100.xtc \
    -o simulation/analysis/md_nojump.xtc \
    -pbc nojump     # Remove jumps first

echo "1 0" | gmx trjconv \
    -s simulation/md_0_100.tpr \
    -f simulation/analysis/md_nojump.xtc \
    -o simulation/analysis/md_center.xtc \
    -center -pbc mol -ur compact
```

---

## Performance Tips

| Situation | Recommendation |
|---|---|
| Single NVIDIA GPU | `-gpu_id 0 -ntmpi 1 -ntomp 8` |
| Multi-GPU | `-gpu_id 01 -ntmpi 2 -ntomp 4` |
| CPU only | `-nt 0` (auto-detect) |
| Very large system (>500k atoms) | Use MPI: `mpirun -np 4 gmx_mpi mdrun` |
| Slow PME on CPU | Move PME to GPU: `-pme gpu` (GROMACS 2020+) |

---

## Getting Help

- **GROMACS Manual:** https://manual.gromacs.org/
- **GROMACS Users Mailing List:** https://mailman-1.sys.kth.se/mailman/listinfo/gromacs.org_gmx-users
- **MDTutorials:** http://www.mdtutorials.com/gmx/
- **BioExcel Forum:** https://ask.bioexcel.eu/
- **Stack Exchange Computational Science:** https://scicomp.stackexchange.com/
