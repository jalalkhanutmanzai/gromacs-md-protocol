# Step 1: Prepare Protein Structure

## What This Step Does

Before running any MD simulation, you need a clean protein structure:
- **Remove water molecules** — crystal waters from the PDB file are not needed (GROMACS will add explicit solvent)
- **Remove ligand HETATM records** — the ligand will be handled separately in Step 2 with proper force field parameters
- **Keep only ATOM records** — standard amino acid atoms

## Prerequisites

- GROMACS installed (`gmx --version`)
- `wget` available (to download from RCSB)
- Completed system check: `bash scripts/00_system_check.sh`

## Input

| Item | Description |
|---|---|
| PDB ID | 4-character code, e.g. `1IEP` |
| Ligand HET code | 3-character HETATM identifier, e.g. `STI` |

**Finding your protein PDB ID:**
1. Go to https://www.rcsb.org
2. Search for your protein by name, gene, or UniProt ID
3. Choose a structure with good resolution (<2.5 Å) and your ligand bound
4. Note the 4-character PDB ID (e.g., `1IEP`) and the ligand HET code (shown in the Structure section)

**Finding the ligand HET code:**
- Download the PDB file and search for `HETATM` lines
- The 4th column (residue name) is your ligand HET code
- Example: `HETATM 3821  C1  STI` → HET code is `STI`

## Commands

### Option A: Run the script (recommended)

Edit the configuration at the top of the script first:

```bash
nano scripts/01_prepare_protein.sh
# Change PDB_ID and LIGAND_ID to your values
```

Then run:

```bash
bash scripts/01_prepare_protein.sh
```

### Option B: Run commands manually

```bash
# Create working directory
mkdir -p simulation
cd simulation

# Download PDB file from RCSB
wget https://files.rcsb.org/download/1IEP.pdb

# Inspect the file
grep "^HETATM" 1IEP.pdb | awk '{print $4}' | sort | uniq -c
# Shows all non-protein atoms (waters, ligands, metals, etc.)

# Remove water molecules
grep -v "^HETATM.*HOH" 1IEP.pdb > 1IEP_nowater.pdb

# Extract only protein ATOM records
grep "^ATOM" 1IEP_nowater.pdb > protein_clean.pdb

# Extract ligand HETATM records (replace STI with your ligand ID)
grep "^HETATM.*STI" 1IEP.pdb > ligand_raw.pdb

# Verify results
wc -l protein_clean.pdb ligand_raw.pdb
```

## Output

| File | Description |
|---|---|
| `simulation/protein_clean.pdb` | Cleaned protein (ATOM records only) |
| `simulation/ligand_raw.pdb` | Raw ligand structure for Step 2 |
| `simulation/1IEP.pdb` | Original downloaded PDB |

## What to Check After This Step

**1. Missing residues**

Open `protein_clean.pdb` in PyMOL or VMD and look for gaps in the backbone. Missing residues are listed in the PDB REMARK 465 section:

```bash
grep "REMARK 465" 1IEP.pdb
```

If there are missing residues, you have three options:
- **Ignore them** if they are in flexible loops far from the binding site
- **Model them** using Modeller or Swiss-Model
- **Choose a different PDB entry** with fewer missing residues

**2. Multiple chains**

```bash
grep "^ATOM" protein_clean.pdb | awk '{print $5}' | sort | uniq
# Shows chain IDs (A, B, C, etc.)
```

If your protein is a monomer, keep only chain A:
```bash
grep "^ATOM.*  A " protein_clean.pdb > protein_chainA.pdb
mv protein_chainA.pdb protein_clean.pdb
```

**3. Non-standard amino acids**

```bash
grep "^ATOM" protein_clean.pdb | awk '{print $4}' | sort | uniq
# Check for anything other than ALA, ARG, ASN, ASP, CYS, GLN, GLU,
# GLY, HIS, ILE, LEU, LYS, MET, PHE, PRO, SER, THR, TRP, TYR, VAL
```

Non-standard residues (e.g., phosphorylated residues, selenomethionine) need special handling.

**4. Visualize the structure**

```bash
# In VMD:
vmd simulation/protein_clean.pdb

# In PyMOL:
pymol simulation/protein_clean.pdb
```

## Common Problems

| Problem | Solution |
|---|---|
| `wget: command not found` | Install wget: `sudo apt install wget` or use `curl -O` |
| PDB download fails | Download manually from https://www.rcsb.org |
| `protein_clean.pdb` is empty | Check that your PDB has `^ATOM` records |
| `ligand_raw.pdb` is empty | The LIGAND_ID doesn't match — check the HET code in the PDB |
| Missing residues in structure | Choose a higher-quality PDB or model missing regions |

## Next Step

```bash
bash scripts/02_prepare_ligand.sh
```

See [02_prepare_ligand.md](02_prepare_ligand.md) for details.
