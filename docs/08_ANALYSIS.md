# 08 — Trajectory Analysis

After the production MD run is complete, analyse the trajectory to extract
biologically meaningful information.

---

## 8.1 Prepare the trajectory

Before analysis, remove periodic boundary condition (PBC) artefacts and
centre the protein in the box.

```bash
source config/config.env
mkdir -p results
cd work/06_md

# Centre protein, remove PBC jumps
printf "Protein\nSystem\n" | gmx trjconv \
    -s md.tpr \
    -f md.xtc \
    -o md_noPBC.xtc \
    -pbc mol \
    -center

# Align trajectory to the first frame (removes overall rotation/translation)
printf "Backbone\nSystem\n" | gmx trjconv \
    -s md.tpr \
    -f md_noPBC.xtc \
    -o md_fit.xtc \
    -fit rot+trans
```

---

## 8.2 RMSD — Root Mean Square Deviation

Measures how much the protein (or ligand) deviates from the starting structure
over time.  A stable RMSD plateau indicates the system is equilibrated.

```bash
cd work/06_md

# Protein backbone RMSD
printf "Backbone\nBackbone\n" | gmx rms \
    -s md.tpr \
    -f md_fit.xtc \
    -o ../../results/rmsd_protein.xvg \
    -tu ns

# Ligand RMSD (replace "LIG" with your ligand group name)
printf "Backbone\nLIG\n" | gmx rms \
    -s md.tpr \
    -f md_fit.xtc \
    -o ../../results/rmsd_ligand.xvg \
    -tu ns
```

---

## 8.3 RMSF — Root Mean Square Fluctuation

Measures per-residue flexibility.  High RMSF = flexible loop region.

```bash
printf "Backbone\nBackbone\n" | gmx rmsf \
    -s md.tpr \
    -f md_fit.xtc \
    -o ../../results/rmsf_backbone.xvg \
    -res
```

---

## 8.4 Radius of gyration (Rg)

Measures protein compactness.  A stable Rg indicates the protein maintains
its overall fold.

```bash
printf "Protein\n" | gmx gyrate \
    -s md.tpr \
    -f md_fit.xtc \
    -o ../../results/rg.xvg
```

---

## 8.5 Hydrogen bonds

Count hydrogen bonds between protein and ligand over time.

```bash
# Select "Protein" for group 1 and your ligand for group 2
printf "Protein\nLIG\n" | gmx hbond \
    -s md.tpr \
    -f md_fit.xtc \
    -num ../../results/hbond_prot_lig.xvg
```

---

## 8.6 SASA — Solvent Accessible Surface Area

Measures how much of the protein surface is exposed to solvent.

```bash
printf "Protein\n" | gmx sasa \
    -s md.tpr \
    -f md_fit.xtc \
    -o ../../results/sasa.xvg
```

---

## 8.7 Plotting XVG files with Python

GROMACS writes analysis output as `.xvg` files.  
Simple Python plotting:

```python
import numpy as np
import matplotlib.pyplot as plt

def load_xvg(fname):
    """Load a GROMACS XVG file, skipping comment/label lines."""
    data = []
    with open(fname) as f:
        for line in f:
            if line.startswith(('@', '#')):
                continue
            data.append([float(x) for x in line.split()])
    return np.array(data)

# Example: RMSD plot
data = load_xvg('results/rmsd_protein.xvg')
plt.figure()
plt.plot(data[:, 0], data[:, 1] * 10)   # convert nm → Å
plt.xlabel('Time (ns)')
plt.ylabel('RMSD (Å)')
plt.title('Protein backbone RMSD')
plt.tight_layout()
plt.savefig('results/rmsd_protein.png', dpi=150)
plt.show()
```

---

## 8.8 Run the automated analysis script

```bash
bash scripts/07_analysis.sh
```

This script performs steps 8.1–8.6 and saves all `.xvg` files to `results/`.

---

## 8.9 Summary of output files

| File | Content |
|---|---|
| `results/rmsd_protein.xvg` | Protein backbone RMSD vs time |
| `results/rmsd_ligand.xvg` | Ligand RMSD vs time |
| `results/rmsf_backbone.xvg` | Per-residue backbone RMSF |
| `results/rg.xvg` | Radius of gyration vs time |
| `results/hbond_prot_lig.xvg` | H-bonds (protein–ligand) |
| `results/sasa.xvg` | Protein SASA vs time |

> All files in `results/` are gitignored.
