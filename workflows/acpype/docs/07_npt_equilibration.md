# Step 7: NPT Equilibration

## What This Step Does

After NVT, the temperature is stable, but the box size (and hence density) may not be correct. NPT equilibration:

1. **Runs MD with a barostat** — allows the box to change size
2. **Equilibrates the pressure** to 1 bar (atmospheric)
3. **Stabilizes the density** to ~1000 kg/m³ (water density at 300 K)

**NPT** = constant **N**umber of particles, **P**ressure, **T**emperature

**Duration:** 100 ps — usually sufficient for density equilibration

## Why Both NVT and NPT?

| Step | Fixed | Free | Purpose |
|---|---|---|---|
| NVT | Volume | Temperature | Stabilize thermal motion |
| NPT | Pressure | Volume+Density | Stabilize box size |
| Production MD | — | Everything | Collect data |

Running NVT before NPT prevents instabilities that can occur when both temperature and pressure are coupled simultaneously to a poorly-equilibrated system.

## Commands

```bash
cd simulation

# Prepare NPT run
gmx grompp \
    -f ../mdp/npt.mdp \
    -c nvt.gro \
    -r nvt.gro \
    -t nvt.cpt \
    -p topol.top \
    -o npt.tpr \
    -maxwarn 2

# Run NPT equilibration
gmx mdrun \
    -v \
    -deffnm npt
```

**Key grompp flags:**

| Flag | Value | Meaning |
|---|---|---|
| `-c` | `nvt.gro` | Starting coordinates (from NVT) |
| `-r` | `nvt.gro` | Reference coordinates for position restraints |
| `-t` | `nvt.cpt` | **NVT checkpoint** — carries velocities forward |

> **Important:** Always use `-t nvt.cpt` to continue from the NVT velocities. Without it, new random velocities are generated, wasting the NVT equilibration.

## Understanding the Barostat (Parrinello-Rahman)

Configured in `mdp/npt.mdp`:

```ini
pcoupl          = Parrinello-Rahman   ; Barostat algorithm
pcoupltype      = isotropic           ; Equal pressure in all directions
tau_p           = 2.0                 ; Pressure relaxation time (ps)
ref_p           = 1.0                 ; Target pressure (bar)
compressibility = 4.5e-5              ; Water compressibility (bar^-1)
```

**Why Parrinello-Rahman?** It produces the correct NPT ensemble and is recommended for equilibration before production MD. (Note: It can be unstable for very poorly equilibrated systems — if it crashes, try `Berendsen` barostat for the first 10 ps, then switch to Parrinello-Rahman.)

## Check Pressure and Density

```bash
# Extract pressure
echo "17 0" | gmx energy \
    -f simulation/npt.edr \
    -o simulation/npt_pressure.xvg

# Extract density
echo "24 0" | gmx energy \
    -f simulation/npt.edr \
    -o simulation/npt_density.xvg

# Plot
xmgrace simulation/npt_pressure.xvg
xmgrace simulation/npt_density.xvg
```

**Expected results:**

| Quantity | Expected Value | Notes |
|---|---|---|
| Pressure average | ~1 bar | Fluctuations of ±50-100 bar are **normal and expected** |
| Density average | ~1000 kg/m³ | Pure water = 997 kg/m³ at 300 K |

> **Note on pressure fluctuations:** Pressure can fluctuate wildly (±100 bar) in MD — this is physically real and not an error. Only the **time-averaged** pressure should be ~1 bar.

**How to find the group numbers for energy extraction:**

```bash
echo "0" | gmx energy -f simulation/npt.edr -o /dev/null 2>&1 | head -40
# This prints all available energy groups with their numbers
```

## Output

| File | Description |
|---|---|
| `simulation/npt.gro` | NPT equilibrated coordinates |
| `simulation/npt.cpt` | **Checkpoint** (required for production MD) |
| `simulation/npt.edr` | Energy data |
| `simulation/npt_pressure.xvg` | Pressure vs time |
| `simulation/npt_density.xvg` | Density vs time |

## Is the System Equilibrated?

The system is considered equilibrated when:
- ✓ Temperature is stable at 300 K (from NVT)
- ✓ Pressure fluctuates around 1 bar
- ✓ Density is stable around 1000 kg/m³
- ✓ No significant drift in potential energy

If density keeps changing linearly, run a longer NPT (200 ps). Change `nsteps = 100000` in `npt.mdp`.

## Common Problems

| Problem | Solution |
|---|---|
| System explodes (atoms fly away) | NVT equilibration was insufficient; go back and extend NVT |
| Density far from 1000 kg/m³ | Check that `ref_p = 1.0` and `compressibility = 4.5e-5` |
| Pressure barostat crashes | Try `pcoupl = Berendsen` for first 10 ps, then switch to Parrinello-Rahman |
| "Energy group names not found" | Check `tc-grps` and `tc_grps` match your topology groups |

## Next Step

```bash
bash scripts/08_production_md.sh
```

See [08_production_md.md](08_production_md.md) for details.
