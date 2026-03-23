# Step 9: Analysis

## What This Step Does

After the 100 ns production MD, we extract meaningful results:

| Analysis | Tool | Tells You |
|---|---|---|
| RMSD | `gmx rms` | Is the protein structure stable? |
| RMSF | `gmx rmsf` | Which residues are flexible? |
| Radius of Gyration | `gmx gyrate` | Does the protein remain folded? |
| H-bonds | `gmx hbond` | How many H-bonds between protein and ligand? |
| SASA | `gmx sasa` | How much surface is exposed to solvent? |
| Ligand RMSD | `gmx rms` | Does the ligand stay in the binding site? |

## Step 0: Fix Periodic Boundary Conditions

Trajectory visualization often shows molecules "jumping" across the box. Fix this first:

```bash
cd simulation

# Center protein and make trajectory continuous
# When prompted: select "1" for Protein (center), then "0" for System (output)
echo "1 0" | gmx trjconv \
    -s md_0_100.tpr \
    -f md_0_100.xtc \
    -o analysis/md_center.xtc \
    -center \
    -pbc mol \
    -ur compact
```

**Flags:**

| Flag | Meaning |
|---|---|
| `-center` | Center the protein in the box |
| `-pbc mol` | Make molecules whole (fix broken molecules at box boundary) |
| `-ur compact` | Use compact representation of the unit cell |

Use `analysis/md_center.xtc` for all subsequent analyses and for visualization.

## Analysis 1: Protein Backbone RMSD

RMSD measures how much the protein deviates from the starting structure.

```bash
mkdir -p analysis

# Select backbone (4) for both reference and group to analyze
echo "4 4" | gmx rms \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/rmsd_protein.xvg \
    -tu ns
```

**Interpreting RMSD:**

| RMSD Value | Interpretation |
|---|---|
| < 2 Å | Stable — protein stays close to crystal structure |
| 2–3 Å | Moderate — some conformational changes |
| > 5 Å | Large change — may indicate unfolding or domain motion |

A good simulation shows RMSD stabilizing (plateau) after ~20-30 ns.

**Plot:**
```bash
xmgrace analysis/rmsd_protein.xvg
# X-axis: Time (ns), Y-axis: RMSD (nm)
```

## Analysis 2: Ligand RMSD

Did the ligand stay in the binding site, or drift away?

```bash
# Fit to protein backbone (4), measure ligand deviation
# Replace "LIG" with your ligand residue name if different
echo "4 LIG" | gmx rms \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/rmsd_ligand.xvg \
    -tu ns
```

**Interpreting ligand RMSD:**
- < 2 Å: Ligand is stable in binding site
- 2–4 Å: Some flexibility/reorientation in binding site
- > 5 Å: Ligand may have left the binding site — visualize!

## Analysis 3: Per-Residue RMSF

RMSF (Root Mean Square Fluctuation) shows the flexibility of each residue.

```bash
echo "1" | gmx rmsf \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/rmsf.xvg \
    -res
```

**Interpreting RMSF:**
- High peaks: Flexible regions (typically loops, termini, disordered regions)
- Low values: Rigid regions (α-helices, β-strands)
- Active site residues should generally have low RMSF (stable for binding)

```bash
xmgrace analysis/rmsf.xvg
# X-axis: Residue number, Y-axis: RMSF (nm)
```

## Analysis 4: Radius of Gyration

Rg measures the overall compactness/folding of the protein.

```bash
echo "1" | gmx gyrate \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/gyrate.xvg
```

**Interpreting Rg:**
- Stable Rg: Protein remains folded throughout simulation
- Increasing Rg: Protein is unfolding — the simulation may be wrong or the protein genuinely unfolds

## Analysis 5: Protein-Ligand Hydrogen Bonds

How many hydrogen bonds form between protein and ligand over time?

```bash
# Select protein (1) and ligand by name
echo "1 LIG" | gmx hbond \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -num analysis/hbond.xvg
```

**Interpreting H-bonds:**
- Average number of H-bonds indicates binding stability
- H-bond count over time shows if binding is maintained or weakened
- Key H-bonds can be identified by loading the trajectory in VMD

## Analysis 6: Solvent Accessible Surface Area

```bash
echo "1" | gmx sasa \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/sasa.xvg
```

## Visualization with VMD

Load the trajectory for visual inspection:

```
1. Open VMD
2. File → New Molecule
3. Load md_0_100.tpr (as "GROMACS GRO" or "Auto")
4. File → Load Data Into Molecule
5. Select md_center.xtc as the trajectory
6. Play the animation to watch the simulation
```

Useful VMD representations:
- Protein: NewCartoon (shows secondary structure)
- Ligand: Licorice or VDW
- Active site: CPK spheres

## Creating Publication-Quality Plots with Python

Instead of xmgrace, you can use Python/matplotlib:

```python
import os
import matplotlib.pyplot as plt
import numpy as np

os.makedirs('simulation/analysis', exist_ok=True)

def read_xvg(filename):
    """Read GROMACS .xvg file, skipping comment lines."""
    x, y = [], []
    with open(filename) as f:
        for line in f:
            if line.startswith('#') or line.startswith('@'):
                continue
            parts = line.split()
            if len(parts) >= 2:
                x.append(float(parts[0]))
                y.append(float(parts[1]))
    return np.array(x), np.array(y)

# Plot RMSD
fig, axes = plt.subplots(2, 2, figsize=(12, 8))

t, rmsd = read_xvg('simulation/analysis/rmsd_protein.xvg')
axes[0,0].plot(t, rmsd * 10)  # convert nm to Angstrom
axes[0,0].set_xlabel('Time (ns)')
axes[0,0].set_ylabel('RMSD (Å)')
axes[0,0].set_title('Protein Backbone RMSD')

t, rmsf = read_xvg('simulation/analysis/rmsf.xvg')
axes[0,1].plot(t, rmsf * 10)
axes[0,1].set_xlabel('Residue')
axes[0,1].set_ylabel('RMSF (Å)')
axes[0,1].set_title('Per-Residue RMSF')

t, rg = read_xvg('simulation/analysis/gyrate.xvg')
axes[1,0].plot(t, rg * 10)
axes[1,0].set_xlabel('Time (ns)')
axes[1,0].set_ylabel('Rg (Å)')
axes[1,0].set_title('Radius of Gyration')

t, hb = read_xvg('simulation/analysis/hbond.xvg')
axes[1,1].plot(t, hb)
axes[1,1].set_xlabel('Time (ns)')
axes[1,1].set_ylabel('Number of H-bonds')
axes[1,1].set_title('Protein-Ligand H-bonds')

plt.tight_layout()
plt.savefig('simulation/analysis/summary_plots.png', dpi=300)
plt.show()
```

Save this script as `scripts/plot_analysis.py` and run:
```bash
python3 scripts/plot_analysis.py
```

## Common Problems

| Problem | Solution |
|---|---|
| `Group not found` | Run `gmx make_ndx` to see available groups |
| `xvg` file is empty | The trajectory may be corrupt; check `gmx check -f md_0_100.xtc` |
| PBC artifacts in trajectory | Repeat `trjconv` step with different PBC options |
| RMSD keeps increasing | May indicate unfolding — check temperature equilibration |
| Ligand leaves binding site | This is a real result — binding may be weak at 300 K |

## Next Steps / Further Analysis

After basic analysis, consider:

- **MM-PBSA/MM-GBSA** binding free energy calculation (`gmx_MMPBSA` tool)
- **Principal Component Analysis (PCA)** of protein motion (`gmx covar`, `gmx anaeig`)
- **Contact map analysis** — which residues are in contact with the ligand?
- **Binding site water analysis** — water molecules in the active site
- **Free energy perturbation** for more accurate ΔG calculations

See the GROMACS documentation: https://manual.gromacs.org/current/reference-manual/
