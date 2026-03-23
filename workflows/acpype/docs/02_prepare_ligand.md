# Step 2: Prepare Ligand Topology

## What This Step Does

Small molecule ligands (drugs, inhibitors, substrates) are **not** covered by standard protein force fields like CHARMM36 or AMBER. We need to:

1. **Assign GAFF2 atom types** — GAFF2 (General AMBER Force Field version 2) covers most drug-like organic molecules
2. **Calculate AM1-BCC partial charges** — semi-empirical quantum mechanical charges for each atom
3. **Generate GROMACS topology files** — `.itp` and `.gro` files that GROMACS can read

This is done using:
- **antechamber** (from AmberTools) — assigns atom types and charges
- **ACPYPE** — converts Amber format to GROMACS format

## Prerequisites

- `antechamber` installed (`antechamber -h`)
- `acpype` installed (`acpype --help`)
- `simulation/ligand_raw.pdb` from Step 1

## What You Need to Know First: Ligand Net Charge

You **must** know the net formal charge of your ligand (an integer):

| Ligand | Net Charge |
|---|---|
| Most neutral drugs (imatinib, etc.) | 0 |
| ATP | -4 |
| GTP | -4 |
| ADP | -3 |
| Phosphorylated serine | -1 |

**How to find it:**
- Check the PubChem page for your ligand (look for "Formal Charge")
- Check the ligand's ChEMBL entry
- Look at the literature (methods section usually states the protonation state)
- At physiological pH (7.4), most carboxylic acids are deprotonated (−1), most amines are protonated (+1)

## Commands

### Option A: Run the script

```bash
nano scripts/02_prepare_ligand.sh
# Set LIGAND_CHARGE to the correct value (e.g., 0 for imatinib)
```

```bash
bash scripts/02_prepare_ligand.sh
```

### Option B: Run commands manually

```bash
cd simulation

# Step 1: Assign GAFF2 atom types and AM1-BCC partial charges
# Replace -nc 0 with the actual net charge of your ligand
antechamber \
    -i ligand_raw.pdb \
    -fi pdb \
    -o LIG.mol2 \
    -fo mol2 \
    -c bcc \
    -s 2 \
    -nc 0 \
    -at gaff2
```

**Command breakdown:**

| Flag | Value | Meaning |
|---|---|---|
| `-i` | `ligand_raw.pdb` | Input file |
| `-fi` | `pdb` | Input format: PDB |
| `-o` | `LIG.mol2` | Output file |
| `-fo` | `mol2` | Output format: MOL2 (includes charge info) |
| `-c` | `bcc` | Charge method: AM1-BCC (recommended for drug-like molecules) |
| `-s` | `2` | Show warnings |
| `-nc` | `0` | Net charge of the molecule |
| `-at` | `gaff2` | Atom type: GAFF2 |

```bash
# Step 2: Check for missing force field parameters
parmchk2 \
    -i LIG.mol2 \
    -f mol2 \
    -o LIG.frcmod

# If LIG.frcmod has entries, some parameters were estimated — usually OK

# Step 3: Generate GROMACS topology with ACPYPE
acpype \
    -i LIG.mol2 \
    -b LIG_GMX \
    -c bcc \
    -n 0 \
    -a gaff2
```

**ACPYPE output directory:** `LIG_GMX.acpype/`

```bash
# Copy the files we need to simulation/
cp LIG_GMX.acpype/LIG_GMX_GMX.gro ligand.gro
cp LIG_GMX.acpype/LIG_GMX_GMX.itp ligand.itp
```

## Output

| File | Description |
|---|---|
| `simulation/ligand.gro` | Ligand coordinates in GROMACS format |
| `simulation/ligand.itp` | Ligand topology (force field parameters) |
| `simulation/LIG.mol2` | Intermediate MOL2 with charges |
| `simulation/LIG_GMX.acpype/` | Full ACPYPE output directory |

## Understanding ligand.itp

The `ligand.itp` file contains sections like:

```
[ moleculetype ]
LIG   3    ; name and nrexcl

[ atoms ]
; atom type, charge, ...

[ bonds ]
...

[ angles ]
...

[ dihedrals ]
...
```

This file will be `#include`'d in `topol.top` in Step 3.

## Common Problems

| Problem | Solution |
|---|---|
| `antechamber: command not found` | Install AmberTools: `conda install -c conda-forge ambertools` |
| `acpype: command not found` | Install: `pip3 install acpype` |
| `Fatal: cannot read the file` | Check `ligand_raw.pdb` exists and is not empty |
| AM1-BCC charge calculation fails | Try `-c gas` (gas-phase charges) or use `-c bcc` with a simpler structure |
| ACPYPE: "too many atoms" | Ligand is very large — try with a smaller fragment |
| Unusual atom types in `.frcmod` | GAFF2 may not have parameters — try `-at gaff` (GAFF v1) |
| Wrong charge assigned | Double-check the net charge; try neutralizing protonation manually |

## Alternative: Use CHARMM-CGenFF

If you prefer CHARMM force field parameters for both protein and ligand:

1. Go to https://cgenff.umaryland.edu
2. Upload your ligand MOL2 file
3. Download the CHARMM-format `.str` file
4. Convert to GROMACS format using `cgenff_charmm2gmx.py`

This gives a CHARMM-consistent parameterization. Both approaches (GAFF2 and CGenFF) are valid and widely published.

## Next Step

```bash
bash scripts/03_build_topology.sh
```

See [03_build_topology.md](03_build_topology.md) for details.
