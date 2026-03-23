# Installation

This guide covers three ways to install GROMACS 2024.x on a Linux system.
Choose the method that best matches your environment.

---

## Option 1 — apt package manager (Ubuntu/Debian, quickest for testing)

```bash
sudo apt update
sudo apt install -y gromacs gromacs-openmpi
gmx --version
```

> **Note:** The Ubuntu package may lag behind the upstream release.
> For GROMACS 2024.x, use Option 2 or Option 3 for exact version control.

---

## Option 2 — Conda / Mamba (recommended for reproducibility)

### 2a. Install Mamba (fast conda drop-in)

```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
bash Miniforge3-Linux-x86_64.sh -b -p "$HOME/miniforge3"
source "$HOME/miniforge3/etc/profile.d/conda.sh"
conda activate base
```

### 2b. Create the GROMACS environment

```bash
mamba create -n gmx2024 -c conda-forge gromacs=2024.3 cudatoolkit=12.2 -y
conda activate gmx2024
gmx --version
```

> GPU acceleration via CUDA is included when `cudatoolkit` is specified.
> Match the CUDA version to your driver (`nvidia-smi` shows the driver version).

### 2c. Export the environment for reproducibility

```bash
conda env export > environment.yml
# Commit environment.yml to version control (it contains no results)
```

---

## Option 3 — Apptainer / Singularity container (best for HPC)

Many university HPC clusters support Apptainer (formerly Singularity).
A pre-built GROMACS container is available from NVIDIA NGC:

```bash
# Pull the GROMACS container (requires Apptainer ≥ 1.0)
apptainer pull gromacs_2024.3.sif docker://nvcr.io/hpc/gromacs:2024.3

# Test it
apptainer exec --nv gromacs_2024.3.sif gmx --version

# Run mdrun inside the container
apptainer exec --nv gromacs_2024.3.sif gmx mdrun -v -deffnm md
```

> `--nv` passes the host GPU to the container.
> Replace `nvcr.io/hpc/gromacs:2024.3` with the tag matching your version;
> browse available tags at https://catalog.ngc.nvidia.com/orgs/hpc/containers/gromacs

---

## Verifying the installation

```bash
# Should print version info and list GPU devices if CUDA is working
gmx --version
nvidia-smi
```

Expected output excerpt:

```
GROMACS version:    2024.3
CUDA support:       enabled
```

---

## CUDA / GPU driver notes

| GROMACS version | Required CUDA | Recommended driver |
|---|---|---|
| 2024.3 | ≥ 11.0 | ≥ 525 (for CUDA 12.x) |
| 2023.x | ≥ 10.2 | ≥ 450 |

Check your driver version with:

```bash
nvidia-smi --query-gpu=driver_version --format=csv,noheader
```

