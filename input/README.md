# Input Files Guide

This directory holds your **system-specific input files**.  
It is listed in `.gitignore` — files here are **never committed** to git.

---

## What Belongs Here

```
input/
├── protein_clean.pdb        ← Cleaned protein structure (REQUIRED)
└── charmm_ligand/           ← CHARMM-GUI/CGenFF export folder (REQUIRED)
    ├── lig_ini.pdb           ← Ligand coordinates
    ├── lig.itp               ← Ligand GROMACS topology
    ├── lig.prm               ← Ligand force-field parameters
    └── (other CHARMM-GUI files)
```

---

## How to Prepare Each File

### 1. `protein_clean.pdb` — Cleaned Protein Structure

**a. Download the structure**
```bash
# Example: download 1HSG from RCSB PDB
wget https://files.rcsb.org/download/1HSG.pdb -O raw_protein.pdb
```

**b. Clean with PyMOL**
```python
# In PyMOL:
load raw_protein.pdb
remove resn HOH         # remove water molecules
remove resn LIG         # remove existing ligand (we add it separately)
remove hetatm           # remove all HETATM records
save protein_clean.pdb, polymer
```

**c. Or clean with pdbfixer (command line)**
```bash
pip install pdbfixer
pdbfixer raw_protein.pdb \
    --keep-heterogens=none \
    --add-atoms=all \
    --add-residues \
    --output=protein_clean.pdb
```

> **Tips:**
> - Remove all non-protein atoms (water, ions, crystallographic ligands)
> - Keep only the biological chain(s) you want to simulate
> - Ensure no residue numbering gaps that confuse pdb2gmx

---

### 2. `charmm_ligand/` — Ligand Topology from CHARMM-GUI

**a. Go to [CHARMM-GUI Ligand Reader & Modeller](https://charmm-gui.org/?doc=input/ligandrm)**

**b. Upload your ligand:**
- Upload a `.mol2` or `.sdf` file from PubChem / ChemDraw / Avogadro

**c. Select parameters:**
- Force Field: **CHARMM CGenFF**
- File format: **GROMACS**

**d. Download and extract the archive.**  
You need at minimum:

| File | Purpose |
|---|---|
| `lig_ini.pdb` | Initial ligand coordinates |
| `lig.itp` | GROMACS topology for the ligand |
| `lig.prm` | CGenFF force-field parameters |

**e. Place them in `input/charmm_ligand/`:**
```bash
mkdir -p input/charmm_ligand
cp /path/to/charmm-gui-output/lig* input/charmm_ligand/
```

---

### 3. Edit `config/config.env`

Ensure the config matches your file names:

```bash
PROTEIN_PDB=protein_clean.pdb
LIGAND_DIR=charmm_ligand
LIGAND_ITP=lig.itp
LIGAND_PDB=lig_ini.pdb
LIGAND_MOLNAME=LIG        # must match the [ moleculetype ] name in lig.itp
```

---

## Obtaining Ligand Structures

| Source | Use case |
|---|---|
| [PubChem](https://pubchem.ncbi.nlm.nih.gov/) | Download known drugs/metabolites as SDF/MOL2 |
| [ChemDraw](https://www.perkinelmer.com/chemdraw) | Draw and export novel molecules |
| [Avogadro](https://avogadro.cc/) | Free open-source molecule builder |
| [LigParGen](http://zarbi.chem.yale.edu/ligpargen/) | OPLS-AA parameters (alternative to CGenFF) |

---

## Verifying Your Inputs

Run the system check — it will tell you if any expected files are missing:

```bash
bash scripts/00_system_check.sh
```

Or use make:

```bash
make check
```

---

> **Remember:** Never commit files from this directory to git.  
> Keep your unpublished structures private.
