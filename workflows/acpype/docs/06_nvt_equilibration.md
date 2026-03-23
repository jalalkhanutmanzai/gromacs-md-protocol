# Step 6: NVT Equilibration

## What This Step Does

After energy minimization, atoms have positions but **no velocities** (no motion). NVT equilibration:

1. **Assigns random velocities** to all atoms from a Maxwell-Boltzmann distribution at 300 K
2. **Runs short MD** (100 ps) while keeping the volume fixed
3. **Stabilizes the temperature** at 300 K using a thermostat
4. **Keeps protein in place** with position restraints (allows solvent to relax)

**NVT** = constant **N**umber of particles, **V**olume, **T**emperature

## Why Is This Necessary?

Without equilibration, jumping directly to production MD would:
- Cause the system to violently "explode" due to bad initial velocities
- Lead to incorrect temperature and pressure
- Produce unreliable trajectory data

Equilibration gradually brings the system to the correct thermodynamic state.

## Position Restraints

During NVT, **protein heavy atoms are restrained** using `posre.itp`. This:
- Prevents the protein from moving while water adjusts around it
- Uses a harmonic force constant of 1000 kJ/mol/nm² by default
- Only applies when `define = -DPOSRES` is in the MDP file

The restraints are released in production MD.

## Commands

```bash
cd simulation

# Prepare NVT run
gmx grompp \
    -f ../mdp/nvt.mdp \
    -c em.gro \
    -r em.gro \
    -p topol.top \
    -o nvt.tpr \
    -maxwarn 2

# Run NVT equilibration
gmx mdrun \
    -v \
    -deffnm nvt
```

**Key grompp flags:**

| Flag | Value | Meaning |
|---|---|---|
| `-f` | `nvt.mdp` | NVT parameters |
| `-c` | `em.gro` | Starting coordinates (from energy minimization) |
| `-r` | `em.gro` | **Reference coordinates for position restraints** |
| `-p` | `topol.top` | Topology |
| `-o` | `nvt.tpr` | Output run input file |

> **Important:** The `-r em.gro` flag provides reference positions for the restraints. Without it, position restraints won't work correctly.

## Understanding nvt.mdp Settings

Key parameters in `mdp/nvt.mdp`:

```ini
; Thermostat
tcoupl    = V-rescale       ; Velocity rescaling (more accurate than Berendsen)
tc-grps   = Protein_LIG Water_and_ions  ; Two separate thermostat groups
ref_t     = 300  300        ; Target temperature for each group (K)
tau_t     = 0.1  0.1        ; Coupling time constant (ps)

; Initial velocities
gen_vel   = yes             ; Generate velocities
gen_temp  = 300             ; Temperature for velocity generation
```

**Why two thermostat groups?** Coupling protein+ligand and solvent separately prevents the "hot solvent/cold protein" artifact where energy flows incorrectly between the two.

## Check Temperature Equilibration

```bash
# Extract temperature from energy file
echo "16 0" | gmx energy \
    -f simulation/nvt.edr \
    -o simulation/nvt_temperature.xvg

# Plot
xmgrace simulation/nvt_temperature.xvg
```

**Expected result:** Temperature should start near 300 K and remain stable (±5 K fluctuation is normal).

If temperature is far from 300 K:
- Check that `ref_t = 300 300` in `nvt.mdp`
- Check `tc-grps` matches your group names (run `gmx make_ndx -f em.gro` to see groups)

## Output

| File | Description |
|---|---|
| `simulation/nvt.gro` | NVT equilibrated coordinates |
| `simulation/nvt.cpt` | **Checkpoint file** (required for NPT step) |
| `simulation/nvt.edr` | Energy data (temperature, etc.) |
| `simulation/nvt.log` | Simulation log |

## Common Problems

| Problem | Solution |
|---|---|
| Temperature far from 300 K | Check `tc-grps` — group names must match GROMACS index groups |
| `Fatal: Group 'Protein_LIG' not found` | Use `gmx make_ndx` to find correct group names, or use `Protein` + `non-Protein` |
| Simulation crashes (LINCS warnings) | Energy minimization was insufficient; re-run EM with looser tolerance |
| "Illegal instruction" error | GROMACS binary not compatible with your CPU — compile from source |

## How to Find Correct Group Names

If you get group name errors, run:

```bash
gmx make_ndx -f simulation/em.gro -o simulation/index.ndx
# Type "q" to quit
# The output shows all available groups and their numbers
```

Then edit `nvt.mdp`:
```ini
tc-grps = Protein Non-Protein   ; Use these if Protein_LIG doesn't work
```

## Next Step

```bash
bash scripts/07_npt_equilibration.sh
```

See [07_npt_equilibration.md](07_npt_equilibration.md) for details.
