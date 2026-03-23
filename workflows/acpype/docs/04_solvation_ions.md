# Step 4: Solvation and Ion Addition

## What This Step Does

Proteins in cells are not in vacuum — they are surrounded by water and ions. This step:

1. **Defines the simulation box** — a dodecahedral box around the protein-ligand complex
2. **Fills with water** — explicit TIP3P water molecules
3. **Adds Na+ and Cl- ions** — to neutralize system charge and reach physiological salt concentration (0.15 M NaCl)

## Why Explicit Solvent?

MD simulations use **explicit solvent** — each water molecule is individually simulated. This is more accurate than implicit solvent models but requires more computation. For a typical protein of ~300 residues in a dodecahedral box:
- ~30,000 water molecules
- ~100 Na+ and Cl- ions
- Total system: ~100,000 atoms

## Step 1: Define Simulation Box

```bash
cd simulation

gmx editconf \
    -f complex.gro \
    -o complex_box.gro \
    -c \
    -d 1.0 \
    -bt dodecahedron
```

**Command breakdown:**

| Flag | Value | Meaning |
|---|---|---|
| `-f` | `complex.gro` | Input: protein+ligand coordinates |
| `-o` | `complex_box.gro` | Output: coordinates with box defined |
| `-c` | — | Center the molecule in the box |
| `-d` | `1.0` | Minimum distance from protein to box wall (nm) |
| `-bt` | `dodecahedron` | Box type |

**Box type choices:**

| Type | Shape | Volume vs Cube | Best for |
|---|---|---|---|
| `dodecahedron` | Rhombic dodecahedron | ~71% less water | Standard MD |
| `cubic` | Cube | Baseline | Simple setups |
| `triclinic` | Arbitrary | Depends | Non-globular proteins |

**Why dodecahedron?** It is the most efficient shape — it minimizes the number of water molecules needed while still satisfying periodic boundary conditions. This reduces simulation cost by ~30%.

## Step 2: Solvate

```bash
gmx solvate \
    -cp complex_box.gro \
    -cs spc216.gro \
    -p topol.top \
    -o complex_solv.gro
```

**Command breakdown:**

| Flag | Value | Meaning |
|---|---|---|
| `-cp` | `complex_box.gro` | Solute (your protein+ligand) |
| `-cs` | `spc216.gro` | Water box template (pre-equilibrated, TIP3P-compatible) |
| `-p` | `topol.top` | Topology — GROMACS **automatically adds** the SOL count |
| `-o` | `complex_solv.gro` | Output: solvated system |

> **Note:** `spc216.gro` is a pre-equilibrated 3-point water box that comes with GROMACS. It works for TIP3P, SPC, and SPC/E water models.

After this step, check `topol.top` — you should see a new line like:
```
SOL    28531
```

## Step 3: Add Ions

Proteins often have a net charge (due to charged amino acids at pH 7). We need to add counter-ions to neutralize this and maintain physiological salt concentration.

```bash
# First, create a temporary .tpr file (required by genion)
gmx grompp \
    -f ../mdp/em.mdp \
    -c complex_solv.gro \
    -p topol.top \
    -o ions.tpr \
    -maxwarn 2

# Add ions (replace SOL molecules)
echo "SOL" | gmx genion \
    -s ions.tpr \
    -o complex_solv_ions.gro \
    -p topol.top \
    -pname NA \
    -nname CL \
    -neutral \
    -conc 0.15
```

**genion flags:**

| Flag | Value | Meaning |
|---|---|---|
| `-s` | `ions.tpr` | Input run file |
| `-o` | `complex_solv_ions.gro` | Output with ions |
| `-p` | `topol.top` | Topology (updated automatically) |
| `-pname` | `NA` | Positive ion (sodium) |
| `-nname` | `CL` | Negative ion (chloride) |
| `-neutral` | — | Add enough ions to neutralize the net charge |
| `-conc` | `0.15` | Additional NaCl to reach 0.15 mol/L (physiological) |

**When prompted:** Type `SOL` to select the solvent group (water molecules will be replaced by ions).

## Step 4: Verify System Composition

```bash
grep -A 20 "\[ molecules \]" topol.top
```

Expected output:
```
[ molecules ]
Protein_chain_A     1
LIG                 1
SOL             28468
NA                 52
CL                 56
```

## Understanding the Output

- **SOL**: Water molecules (reduced from step 2 because some were replaced by ions)
- **NA**: Sodium ions (cation)
- **CL**: Chloride ions (anion)
- **Net charge should be 0** (neutralized)

## Visualize the Solvated System

Before proceeding, it is good practice to visualize `complex_solv_ions.gro` to confirm everything looks correct:

```bash
# In VMD:
vmd simulation/complex_solv_ions.gro
```

You should see the protein (ribbons), ligand (stick/ball), and water box surrounding everything.

## Output

| File | Description |
|---|---|
| `simulation/complex_box.gro` | System with box defined |
| `simulation/complex_solv.gro` | Solvated system |
| `simulation/complex_solv_ions.gro` | **FINAL INPUT** for simulations |
| `simulation/topol.top` | Updated with water/ion counts |

## Common Problems

| Problem | Solution |
|---|---|
| Box too small — protein extends outside | Increase `-d` value (try 1.2 nm) |
| `Fatal error: 2 water molecules can not be added` | Box is too small for the requested water — increase box size |
| genion crashes | Check that `ions.tpr` was created successfully by grompp |
| Wrong ion names | Use `-pname NA -nname CL` (capital letters, no + or -) |
| Net charge not zero after ions | Check the protein charge: `grep 'total charge' grompp.log` |

## Next Step

```bash
bash scripts/05_energy_minimization.sh
```

See [05_energy_minimization.md](05_energy_minimization.md) for details.
