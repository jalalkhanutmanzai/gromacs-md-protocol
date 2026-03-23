# Step 3: Build System Topology

## What This Step Does

Now we have:
- `protein_clean.pdb` — cleaned protein structure
- `ligand.gro` + `ligand.itp` — ligand coordinates and topology

This step:
1. **Generates the protein topology** using `gmx pdb2gmx` (adds hydrogens, assigns CHARMM36 parameters)
2. **Combines protein and ligand** into a single coordinate file (`complex.gro`)
3. **Updates the topology** (`topol.top`) to include the ligand

## Prerequisites

- Step 1 and Step 2 complete
- GROMACS installed
- CHARMM36 force field available (comes with GROMACS)

## Part 1: Generate Protein Topology with pdb2gmx

```bash
cd simulation

gmx pdb2gmx \
    -f protein_clean.pdb \
    -o protein_processed.gro \
    -p topol.top \
    -i posre.itp \
    -ff charmm36-jul2022 \
    -water tip3p \
    -ignh \
    -missing
```

**Command breakdown:**

| Flag | Value | Meaning |
|---|---|---|
| `-f` | `protein_clean.pdb` | Input protein structure |
| `-o` | `protein_processed.gro` | Output coordinates with H atoms |
| `-p` | `topol.top` | Output topology file |
| `-i` | `posre.itp` | Output position restraints file |
| `-ff` | `charmm36-jul2022` | Force field: CHARMM36 (2022 version) |
| `-water` | `tip3p` | Water model compatible with CHARMM36 |
| `-ignh` | — | Ignore all H atoms in input (GROMACS adds correct ones) |
| `-missing` | — | Don't exit on missing atoms |

**Interactive prompts:** If pdb2gmx asks about histidine protonation states:
- `0` = auto (based on local environment) — recommended
- `1` = HID (Nδ protonated)
- `2` = HIE (Nε protonated)  
- `3` = HIP (both protonated, charge +1)

## Part 2: Combine Protein and Ligand Coordinates

The protein is now in `protein_processed.gro` and the ligand is in `ligand.gro`. We need to merge them into one file.

```bash
# Get number of atoms
protein_atoms=$(awk 'NR==2 {print $1}' protein_processed.gro)
ligand_atoms=$(awk 'NR==2 {print $1}' ligand.gro)
total_atoms=$((protein_atoms + ligand_atoms))
echo "Total: $total_atoms atoms"

# Combine: header + protein atoms + ligand atoms + box vectors
{
    head -1 protein_processed.gro     # Title line
    echo "  $total_atoms"             # Total atom count
    # Protein atoms (skip 2-line header, skip last box line)
    tail -n +3 protein_processed.gro | head -n -1
    # Ligand atoms (skip 2-line header, skip last box line)
    tail -n +3 ligand.gro | head -n -1
    # Box vectors (from protein file, last line)
    tail -1 protein_processed.gro
} > complex.gro

echo "complex.gro created with $total_atoms atoms"
```

## Part 3: Update Topology to Include Ligand

Open `topol.top` in a text editor and make two changes:

### Change 1: Add `#include "ligand.itp"` before `[ system ]`

```
; Before:
[ system ]

; After:
; Include ligand topology
#include "ligand.itp"

[ system ]
```

### Change 2: Add ligand to `[ molecules ]` section

```
; Before:
[ molecules ]
Protein_chain_A   1

; After:
[ molecules ]
Protein_chain_A   1
LIG               1
```

> **Important:** The order in `[ molecules ]` must match the order of molecules in the `.gro` file. Protein first, then ligand.

The script does this automatically. If doing it manually:

```bash
# Add include before [ system ]
sed -i '/\[ system \]/i ; Include ligand topology\n#include "ligand.itp"\n' topol.top

# Append ligand to molecules section
echo "LIG               1" >> topol.top
```

## Part 4: Verify the Topology

Always verify the topology is valid before running any simulations:

```bash
gmx grompp \
    -f ../mdp/em.mdp \
    -c complex.gro \
    -p topol.top \
    -o test_check.tpr \
    -maxwarn 5
```

If this succeeds (creates `test_check.tpr`), your topology is valid. Delete the test file:

```bash
rm test_check.tpr
```

## Understanding topol.top

The topology file has this structure:

```
; Include forcefield parameters
#include "charmm36-jul2022.ff/forcefield.itp"

; Include protein topology
#include "topol_Protein_chain_A.itp"

; Include position restraints (used during equilibration)
#ifdef POSRES
#include "posre.itp"
#endif

; Include ligand topology   ← YOU ADD THIS
#include "ligand.itp"

[ system ]
Protein-Ligand MD

[ molecules ]
Protein_chain_A   1
LIG               1    ← AND THIS
```

## Output

| File | Description |
|---|---|
| `simulation/protein_processed.gro` | Protein with correct H atoms |
| `simulation/complex.gro` | Protein + ligand combined |
| `simulation/topol.top` | Complete system topology |
| `simulation/posre.itp` | Position restraints (used in NVT/NPT) |
| `simulation/topol_Protein_chain_A.itp` | Protein-specific topology |

## Common Problems

| Problem | Solution |
|---|---|
| `Fatal error: Residue XX not found` | Non-standard residue; rename or remove it |
| `No force field found` | Specify `-ff` explicitly or run `gmx pdb2gmx` without flags for interactive menu |
| Missing atoms in grompp | Run with `-missing` flag |
| `Total charge X is not close to integer` | Your structure has incorrect protonation; check HIS/ASP/GLU |
| Atom count mismatch in complex.gro | Re-check the combining commands |
| `[ molecules ] not ordered` | Reorder molecules to match the .gro file |

## Next Step

```bash
bash scripts/04_solvation_ions.sh
```

See [04_solvation_ions.md](04_solvation_ions.md) for details.
