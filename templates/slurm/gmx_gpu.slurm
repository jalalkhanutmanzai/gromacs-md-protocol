#!/usr/bin/env bash
# templates/slurm/gmx_gpu.slurm
# ─────────────────────────────────────────────────────────────────────────────
# SLURM job script — GROMACS GPU production MD
#
# Usage:
#   cp templates/slurm/gmx_gpu.slurm my_md_job.slurm
#   # Edit the SBATCH directives below to match your cluster
#   sbatch my_md_job.slurm
#
# Resource mapping:
#   --gres=gpu:N          → gmx mdrun -gpu_id 0,...,N-1
#   --cpus-per-task C     → gmx mdrun -ntomp C
#   --ntasks 1            → gmx mdrun -ntmpi 1   (thread-MPI, single GPU)
# ─────────────────────────────────────────────────────────────────────────────

# ── Job metadata ─────────────────────────────────────────────────────────────
#SBATCH --job-name=gmx_md
#SBATCH --output=slurm_%j.out
#SBATCH --error=slurm_%j.err

# ── Time limit (HH:MM:SS) ────────────────────────────────────────────────────
# 100 ns on a V100S typically takes 24–48 h; set to your cluster's max
#SBATCH --time=48:00:00

# ── Partition and account — edit to match your cluster ───────────────────────
#SBATCH --partition=gpu
#SBATCH --account=YOUR_ACCOUNT

# ── GPU resources ─────────────────────────────────────────────────────────────
#SBATCH --gres=gpu:1           # number of GPUs (increase for multi-GPU)
#SBATCH --constraint=v100      # optional: request specific GPU type

# ── CPU resources ─────────────────────────────────────────────────────────────
# Rule of thumb: use 4–8 CPU cores per GPU
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8

# ── Memory ────────────────────────────────────────────────────────────────────
#SBATCH --mem=16G

# ─────────────────────────────────────────────────────────────────────────────
# Environment setup
# ─────────────────────────────────────────────────────────────────────────────

# Option A: Module-based HPC (uncomment and edit)
# module purge
# module load gromacs/2024.3-cuda
# module load cuda/12.2

# Option B: Conda environment (uncomment and edit)
# source "$HOME/miniforge3/etc/profile.d/conda.sh"
# conda activate gmx2024

# Option C: Apptainer container (uncomment and edit)
# GMX_APPTAINER="apptainer exec --nv $HOME/containers/gromacs_2024.3.sif gmx"

# Load the repo config
REPO_ROOT="${SLURM_SUBMIT_DIR}"
CONFIG="${REPO_ROOT}/config/config.env"
if [ -f "$CONFIG" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG"
fi

GMX="${GMX_BIN:-gmx}"
NTOMP="${SLURM_CPUS_PER_TASK:-${NTOMP:-8}}"   # prefer SLURM setting
NTMPI="${NTMPI:-1}"
GPU_ID="${GPU_ID:-0}"

# ─────────────────────────────────────────────────────────────────────────────
# Pre-process (grompp) — only if md.tpr not already present
# ─────────────────────────────────────────────────────────────────────────────
MD_DIR="${REPO_ROOT}/${WORK_DIR:-work}/06_md"
TOPOLOGY="${REPO_ROOT}/${WORK_DIR:-work}/01_topology/topol.top"
NPT_DIR="${REPO_ROOT}/${WORK_DIR:-work}/05_npt"
MDP="${REPO_ROOT}/${MDP_DIR:-mdp}/${MDP_MD:-md_100ns.mdp}"

mkdir -p "$MD_DIR"
cd "$MD_DIR"

if [ ! -f md.tpr ]; then
    echo "Running grompp..."
    "$GMX" grompp \
        -f "$MDP" \
        -c "${NPT_DIR}/npt.gro" \
        -t "${NPT_DIR}/npt.cpt" \
        -p "$TOPOLOGY" \
        -o md.tpr \
        -maxwarn 2
fi

# ─────────────────────────────────────────────────────────────────────────────
# Run production MD (with checkpoint restart support)
# ─────────────────────────────────────────────────────────────────────────────
RESTART_FLAG=""
if [ -f md.cpt ]; then
    echo "Checkpoint found — restarting from md.cpt"
    RESTART_FLAG="-cpi md.cpt"
fi

echo "Starting gmx mdrun..."
echo "  GPU_ID  = ${GPU_ID}"
echo "  NTMPI   = ${NTMPI}"
echo "  NTOMP   = ${NTOMP}"

# shellcheck disable=SC2086
"$GMX" mdrun \
    -v \
    -deffnm md \
    ${RESTART_FLAG} \
    -gpu_id "${GPU_ID}" \
    -ntmpi "${NTMPI}" \
    -ntomp "${NTOMP}" \
    -pin on \
    -bonded gpu \
    -update gpu

echo "mdrun finished."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Output: ${MD_DIR}/md.xtc"
