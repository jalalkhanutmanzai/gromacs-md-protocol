# 02 — Building the Protein–Ligand Topology

This step generates the GROMACS topology (`.top`) and processed coordinate
file (`.gro`) for the complete protein–ligand complex.

---

## Overview of the process

```
protein_clean.pdb  ──►  gmx pdb2gmx  ──►  protein.gro + protein.top + posre.itp
lig_ini.pdb        ──►  (coordinates only, manually placed)
lig.itp            ──►  merged into topology
                         │
                         ▼
               complex.gro  +  topol.top
```

---

## 2.1 Generate the protein topology with `pdb2gmx`

`gmx pdb2gmx` reads your protein PDB and writes a GROMACS topology using the
chosen force field.

```bash
# Source the config
source config/config.env

mkdir -p work/01_topology
cd work/01_topology

gmx pdb2gmx \
    -f ../../input/protein_clean.pdb \
    -o protein_processed.gro \
    -p topol.top \
    -i posre.itp \
    -ff charmm36-jul2022 \
    -water tip3p \
    -ignh
```

**Flags explained:**

| Flag | Meaning |
|---|---|
| `-f` | Input PDB file |
| `-o` | Output GROMACS coordinate file (.gro) |
| `-p` | Output topology file (.top) |
| `-i` | Position-restraint file for protein heavy atoms |
| `-ff` | Force field (`charmm36-jul2022` — adjust if you use a different one) |
| `-water` | Water model |
| `-ignh` | Ignore (remove) existing hydrogens; let GROMACS add them |

When prompted about protonation states of His residues, accept the default or
specify based on your system.  In a non-interactive script, use:

```bash
echo "1" | gmx pdb2gmx ...   # selects the first option for each prompt
```

---

## 2.2 Process the ligand coordinates

CHARMM-GUI provides `lig_ini.pdb` with the ligand coordinates.  
Convert it to GROMACS format:

```bash
# Still inside work/01_topology/
gmx editconf \
    -f ../../input/charmm_ligand/lig_ini.pdb \
    -o lig.gro
```

---

## 2.3 Merge protein + ligand coordinates

Combine the protein and ligand coordinate files into a single `.gro` file.  
The easiest way is to use the header from the protein `.gro`, append the
ligand atom lines, and update the atom count.

```bash
# Count atoms in each file (skip header line 1 and box line at end)
N_PROT=$(awk 'NR==2 {print $1}' protein_processed.gro)
N_LIG=$(awk 'NR==2 {print $1}' lig.gro)
N_TOTAL=$((N_PROT + N_LIG))

# Combine: header + updated count + protein atoms + ligand atoms + box vector
{
  head -1 protein_processed.gro         # title line
  echo " $N_TOTAL"                       # total atom count
  sed -n '3,$p' protein_processed.gro | head -n "$N_PROT"   # protein atoms
  sed -n '3,$p' lig.gro | head -n "$N_LIG"                   # ligand atoms
  tail -1 protein_processed.gro         # box vector (from protein)
} > complex.gro
```

---

## 2.4 Update the topology to include the ligand

Open `topol.top` in a text editor.  You need to make two additions:

### a) Include the ligand force-field parameters (near the top, after `#include "charmm36-jul2022.ff/forcefield.itp"`)

```
; Ligand parameters from CHARMM-GUI/CGenFF
#include "../../input/charmm_ligand/lig.itp"
```

### b) Add the ligand molecule count (at the bottom, in the `[ molecules ]` section)

```
[ molecules ]
; Compound        #mols
Protein_chain_A   1
LIG               1
```

> **Important:** The molecule name `LIG` must match exactly the `[ moleculetype ]`
> name inside `lig.itp`.  Open `lig.itp` and check the name on the line
> after `[ moleculetype ]`.

---

## 2.5 Run the automated script

The script `scripts/01_prepare_topology.sh` performs steps 2.1–2.4
automatically.  Review it before running:

```bash
bash scripts/01_prepare_topology.sh
```

Output files (in `work/01_topology/`):

| File | Description |
|---|---|
| `complex.gro` | Protein + ligand coordinates |
| `topol.top` | Complete system topology |
| `posre.itp` | Position restraints for protein |

---

## 2.6 Verify the topology

Check that the topology compiles without errors:

```bash
gmx grompp \
    -f ../../mdp/em.mdp \
    -c complex.gro \
    -p topol.top \
    -o test_em.tpr \
    -maxwarn 2
```

If `grompp` exits cleanly (exit code 0), the topology is valid.
Common errors and fixes are in [docs/09_TROUBLESHOOTING.md](09_TROUBLESHOOTING.md).
