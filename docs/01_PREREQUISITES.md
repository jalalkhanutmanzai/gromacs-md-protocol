# 01 — Prerequisites

Before running any simulation you need:

1. GROMACS installed (see [INSTALLATION.md](../INSTALLATION.md))
2. A cleaned protein structure file
3. Ligand parameter files from CHARMM-GUI / CGenFF
4. A working directory layout

---

## 1.1 Required software

| Software | Purpose | Install command |
|---|---|---|
| GROMACS 2024.x | MD engine | see INSTALLATION.md |
| CUDA ≥ 11.0 | GPU acceleration | nvidia driver package |
| VMD or PyMOL | Visualisation | optional |
| Python ≥ 3.8 | Plotting analysis | `conda install python` |
| matplotlib, numpy | Plot XVG files | `pip install matplotlib numpy` |

Verify GROMACS and GPU:

```bash
gmx --version
nvidia-smi
```

---

## 1.2 Input files you must supply

### Protein structure

1. Download your protein from [RCSB PDB](https://www.rcsb.org/).
2. Clean the structure:
   - Remove water molecules and co-crystallised ligands you do not want.
   - Remove HETATM lines that are not your ligand.
   - Keep only chain A (or the relevant chains).
   - Fix missing residues if needed with [pdbfixer](https://github.com/openmm/pdbfixer) or PyMOL.
3. Save as `input/protein_clean.pdb`.

Example cleaning in PyMOL:

```python
# inside PyMOL console
remove resn HOH
remove resn SO4
save input/protein_clean.pdb, polymer
```

### Ligand files from CHARMM-GUI / CGenFF

The recommended workflow for small-molecule ligand parameters:

1. Go to [CHARMM-GUI](https://www.charmm-gui.org/) → **Ligand Reader & Modeller**.
2. Upload your ligand SMILES or SDF/MOL2 file.
3. Choose **GROMACS** as the output format.
4. Download the output ZIP and extract it.
5. You will get (at minimum):
   - `lig.itp` — ligand topology (bonded + non-bonded parameters)
   - `lig.prm` or `fflig.itp` — CHARMM force-field parameters for the ligand
   - `lig.pdb` or `lig_ini.pdb` — ligand coordinates
6. Copy these files into `input/charmm_ligand/`.

```
input/
  charmm_ligand/
    lig.itp
    fflig.itp          (or merged into lig.itp — depends on CHARMM-GUI version)
    lig_ini.pdb
```

> **Tip:** Check the CHARMM-GUI output README for exact file names; they may
> vary slightly between software versions.

---

## 1.3 Directory layout

Create the working and results directories:

```bash
mkdir -p input/charmm_ligand
mkdir -p work/{01_topology,02_solvate,03_em,04_nvt,05_npt,06_md}
mkdir -p results
```

`work/` and `results/` are gitignored so your simulation data stays local.

---

## 1.4 Configure the workflow

Copy and edit the config file:

```bash
cp config/config.env.example config/config.env
```

Open `config/config.env` in your editor and set at least:

- `GMX_BIN` — path to `gmx` binary (leave as `gmx` if it is in your `PATH`)
- `NTOMP` — number of OpenMP threads (match CPU cores on your node)
- `GPU_ID` — GPU index to use (usually `0`)
- `FF_NAME` — force field (default: `charmm36-jul2022`)
- `WATER_MODEL` — water model (default: `tip3p`)

---

## 1.5 Check everything is ready

```bash
bash scripts/00_system_check.sh
```

This script will:

- Print the GROMACS version
- List available GPUs
- Check that the config file exists
- Warn about common missing directories
