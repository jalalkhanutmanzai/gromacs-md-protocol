# 03 — Solvation and Ion Addition

After building the topology, the protein–ligand complex must be placed in an
explicit water box and electrically neutralised with counter-ions.

---

## Overview

```
complex.gro  ──►  editconf  ──►  newbox.gro   (define simulation box)
newbox.gro   ──►  solvate   ──►  solvated.gro (fill box with water)
solvated.gro ──►  genion    ──►  ions.gro      (replace waters with ions)
```

---

## 3.1 Define the simulation box (`editconf`)

`editconf` centres the complex in a periodic box.  
A **dodecahedral** box minimises the number of water molecules for a given
minimum distance between the solute and the box edge.

```bash
source config/config.env

mkdir -p work/02_solvate
cd work/02_solvate

gmx editconf \
    -f ../01_topology/complex.gro \
    -o newbox.gro \
    -c \
    -d 1.0 \
    -bt dodecahedron
```

**Flags explained:**

| Flag | Meaning |
|---|---|
| `-c` | Centre the complex in the box |
| `-d 1.0` | Minimum distance (nm) between solute and box edge (1.0 nm = 10 Å) |
| `-bt dodecahedron` | Box type (dodecahedron is most efficient for globular proteins) |

> **Tip:** Use `-d 1.2` if your protein is large or you expect significant
> conformational changes during the simulation.

---

## 3.2 Solvate the box (`solvate`)

Fill the box with TIP3P water molecules:

```bash
gmx solvate \
    -cp newbox.gro \
    -cs spc216.gro \
    -o solvated.gro \
    -p ../01_topology/topol.top
```

**Flags explained:**

| Flag | Meaning |
|---|---|
| `-cp` | Input: coordinate file (complex in box) |
| `-cs` | Water configuration file (`spc216.gro` is standard for TIP3P) |
| `-o` | Output coordinate file |
| `-p` | Topology file (updated automatically with water count) |

After this step, `topol.top` will contain a `SOL` entry at the bottom of the
`[ molecules ]` section with the number of water molecules added.

---

## 3.3 Add ions (`genion`)

Neutralise the system charge and set the salt concentration to ~0.15 M NaCl
(physiological).

First, pre-process with `grompp` to create a `.tpr` file:

```bash
gmx grompp \
    -f ../../mdp/em.mdp \
    -c solvated.gro \
    -p ../01_topology/topol.top \
    -o ions.tpr \
    -maxwarn 2
```

Then run `genion`, piping the group selection for SOL:

```bash
printf "SOL\n" | gmx genion \
    -s ions.tpr \
    -o ions.gro \
    -p ../01_topology/topol.top \
    -pname NA \
    -nname CL \
    -neutral \
    -conc 0.15
```

**Flags explained:**

| Flag | Meaning |
|---|---|
| `-pname NA` | Name of positive ion (Na⁺) |
| `-nname CL` | Name of negative ion (Cl⁻) |
| `-neutral` | Neutralise total charge first |
| `-conc 0.15` | Additional NaCl to reach 0.15 M |

`genion` will replace randomly selected water molecules with ions.
The topology is updated automatically.

---

## 3.4 Run the automated script

```bash
bash scripts/02_solvate_ions.sh
```

Output files (in `work/02_solvate/`):

| File | Description |
|---|---|
| `newbox.gro` | Complex centred in dodecahedral box |
| `solvated.gro` | Solvated system |
| `ions.gro` | Solvated + neutralised system (final input for EM) |

The topology `work/01_topology/topol.top` is also updated in place.

---

## 3.5 Verify

Check the system composition:

```bash
# Count atom types in the final coordinate file
grep -E "^[[:space:]]+[0-9]+ [A-Z]" work/02_solvate/ions.gro | \
  awk '{print $2}' | sort | uniq -c | sort -rn | head -20
```

Or use `gmx editconf` to print system info:

```bash
gmx editconf -f work/02_solvate/ions.gro -o /dev/null
```

Look for lines like:

```
System has ... atoms
```

A typical protein–ligand system has 30 000–80 000 atoms after solvation.
