# Step 5: Energy Minimization

## What This Step Does

The solvated system (`complex_solv_ions.gro`) may have:
- Bad atomic contacts (atoms too close together from crystal packing)
- Strained bond angles or lengths
- Water molecules overlapping with protein atoms

Energy minimization (EM) moves atoms to remove these clashes by iteratively adjusting positions to lower the potential energy. **This is not dynamics** — there is no time evolution, no temperature. It is a purely geometric optimization.

## Energy Minimization Algorithm: Steepest Descent

GROMACS uses **steepest descent** (configured in `mdp/em.mdp`):

1. Calculate the force on every atom
2. Move each atom a small step in the direction of the force
3. Repeat until the maximum force (`Fmax`) drops below the threshold (1000 kJ/mol/nm)

**Success criterion:** `Fmax < 1000 kJ/mol/nm`

## Commands

```bash
cd simulation

# Step 1: Prepare the run input file
gmx grompp \
    -f ../mdp/em.mdp \
    -c complex_solv_ions.gro \
    -p topol.top \
    -o em.tpr \
    -maxwarn 2

# Step 2: Run energy minimization
gmx mdrun \
    -v \
    -deffnm em
```

**grompp flags:**

| Flag | Value | Meaning |
|---|---|---|
| `-f` | `em.mdp` | Parameter file (steepest descent settings) |
| `-c` | `complex_solv_ions.gro` | Input coordinates |
| `-p` | `topol.top` | Topology |
| `-o` | `em.tpr` | Output binary run input file (TPR) |
| `-maxwarn` | `2` | Allow up to 2 non-fatal warnings |

**mdrun flags:**

| Flag | Value | Meaning |
|---|---|---|
| `-v` | — | Verbose: print progress every step |
| `-deffnm` | `em` | Use "em" as basename for all output files |

## What to Watch During the Run

The output should show decreasing Fmax and potential energy:

```
Step=    0, Dmax= 1.0e-02 nm, Epot= -3.44921e+05 Fmax= 1.11706e+04
Step=    1, Dmax= 1.0e-02 nm, Epot= -3.74152e+05 Fmax= 3.12045e+03
Step=   16, Dmax= 5.0e-04 nm, Epot= -4.26895e+05 Fmax= 9.97521e+02

Steepest Descents converged to Fmax < 1000 in 17 steps
```

If you see:
- "converged to Fmax < 1000" — ✓ success!
- "Stepsize too small" — the minimizer got stuck. Try with a looser tolerance or check your structure.

## Check the Results

```bash
# Extract and plot potential energy
echo "10 0" | gmx energy \
    -f em.edr \
    -o em_potential.xvg

# View the plot
xmgrace em_potential.xvg
```

The potential energy should:
- Start at a large negative number (e.g., −300,000 kJ/mol)
- Decrease (become more negative) as minimization proceeds
- Plateau at the minimum

**Check Fmax in the log file:**
```bash
grep "Fmax" simulation/em.log | tail -5
```

## Understanding Energy Values

For a typical solvated protein-ligand system (~100,000 atoms):

| Quantity | Expected Range | Meaning |
|---|---|---|
| Potential energy | −10⁵ to −10⁷ kJ/mol | Large negative = stable |
| Fmax | < 1000 kJ/mol/nm | Convergence criterion |
| Steps to converge | 100–5000 | Depends on how bad the initial geometry was |

## Output

| File | Description |
|---|---|
| `simulation/em.gro` | Minimized coordinates (input for NVT) |
| `simulation/em.edr` | Energy data |
| `simulation/em.log` | Detailed log (check Fmax here) |
| `simulation/em_potential.xvg` | Potential energy vs step |

## Common Problems

| Problem | Solution |
|---|---|
| `Fmax` never drops below 1000 | Bad initial geometry — check `complex_solv_ions.gro` in VMD |
| `Stepsize too small` after many steps | Set `emtol = 10000` in em.mdp for a looser criterion |
| `Fatal error: charge group X` | Topology error — re-check Step 3 |
| Very large initial Fmax (>10⁶) | Severe steric clashes — check if ligand overlaps with protein |
| Simulation crashes immediately | Check grompp warnings; missing atoms or bad parameters |

## Next Step

```bash
bash scripts/06_nvt_equilibration.sh
```

See [06_nvt_equilibration.md](06_nvt_equilibration.md) for details.
