# Step 8: Production MD (100 ns)

## What This Step Does

The system is now equilibrated. Production MD:

1. **Releases position restraints** — all atoms move freely
2. **Runs 100 ns** of dynamics at 300 K, 1 bar
3. **Saves frames** every 10 ps → 10,000 frames total
4. **Collects data** for RMSD, RMSF, H-bonds, and all other analyses

This is the most computationally intensive step (3–8 hours on GPU, 48–72 hours on CPU).

## Commands

```bash
cd simulation

# Prepare production run (no position restraints — note: no -DPOSRES in md_100ns.mdp)
gmx grompp \
    -f ../mdp/md_100ns.mdp \
    -c npt.gro \
    -t npt.cpt \
    -p topol.top \
    -o md_0_100.tpr \
    -maxwarn 2

# Run on GPU (recommended)
gmx mdrun \
    -v \
    -deffnm md_0_100 \
    -gpu_id 0 \
    -ntmpi 1

# OR: Run on CPU only
gmx mdrun \
    -v \
    -deffnm md_0_100 \
    -nt 0
```

**Key grompp flags:**

| Flag | Value | Meaning |
|---|---|---|
| `-c` | `npt.gro` | Starting coordinates from NPT |
| `-t` | `npt.cpt` | NPT checkpoint carries velocities |
| No `-r` | — | No reference coordinates → no position restraints |

**mdrun GPU flags:**

| Flag | Value | Meaning |
|---|---|---|
| `-gpu_id` | `0` | Use GPU device 0 |
| `-ntmpi` | `1` | 1 MPI rank (single GPU) |
| `-ntomp` | `8` | 8 OpenMP threads per rank (tune to your CPU) |

## Running in Background (Recommended for Long Simulations)

On a local machine or cluster, run in the background so you can log out:

```bash
# Method 1: nohup (survives terminal close)
nohup gmx mdrun -v -deffnm simulation/md_0_100 -gpu_id 0 -ntmpi 1 \
    > simulation/md_0_100.log 2>&1 &

echo "MD running in background (PID: $!)"
```

```bash
# Method 2: screen (recommended — you can re-attach)
screen -S md_simulation
gmx mdrun -v -deffnm simulation/md_0_100 -gpu_id 0 -ntmpi 1
# Press Ctrl+A, D to detach
# screen -r md_simulation to re-attach
```

## Monitoring Progress

While the simulation runs:

```bash
# Check progress (current time in simulation)
tail -n 20 simulation/md_0_100.log | grep "Step\|Time\|ns/day"

# Check for errors
grep -i "error\|fatal\|warning" simulation/md_0_100.log | tail -20

# Check trajectory size
ls -lh simulation/md_0_100.xtc
```

The log file reports performance like:
```
Step   100000, time  200 (ps),  Elapsed  12 (s)
Performance: 5.2 ns/day, 4.6 hours/ns
```

## Resuming an Interrupted Simulation

If your GPU session is cut off (very common with university time limits!), resume from the last checkpoint:

```bash
# Resume from checkpoint — NEVER start from scratch!
gmx mdrun \
    -v \
    -deffnm simulation/md_0_100 \
    -cpi simulation/md_0_100.cpt \
    -append \
    -gpu_id 0 \
    -ntmpi 1
```

**Key flags:**

| Flag | Meaning |
|---|---|
| `-cpi md_0_100.cpt` | Read checkpoint file to continue |
| `-append` | Append new trajectory to existing `.xtc` (don't overwrite) |

> **Tip:** GROMACS saves checkpoint files (`md_0_100.cpt`) every 15 minutes by default. Your simulation will restart from the last checkpoint, not from the beginning.

## Slurm Cluster Job Script

For university HPC clusters using Slurm:

```bash
#!/bin/bash
#SBATCH --job-name=md_simulation
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=12:00:00
#SBATCH --output=md_%j.log

module load gromacs/2022

cd /path/to/gromacs-md-protocol/simulation

gmx mdrun \
    -v \
    -deffnm md_0_100 \
    -gpu_id 0 \
    -ntmpi 1 \
    -ntomp $SLURM_CPUS_PER_TASK \
    -cpi md_0_100.cpt \
    -append
```

Submit with: `sbatch slurm_md.sh`

Check status: `squeue -u $USER`

## Output

| File | Description | Typical Size |
|---|---|---|
| `md_0_100.xtc` | Compressed trajectory (10,000 frames) | ~2-5 GB |
| `md_0_100.edr` | Energy data every 10 ps | ~100 MB |
| `md_0_100.log` | Simulation log | ~50 MB |
| `md_0_100.cpt` | Checkpoint (overwritten every 15 min) | ~20 MB |
| `md_0_100_prev.cpt` | Previous checkpoint (backup) | ~20 MB |
| `md_0_100.tpr` | Run input file (keep for analysis!) | ~10 MB |

> **Note:** Trajectory files (`.xtc`) are in `.gitignore` and will NOT be committed to Git. This is intentional — they are too large and contain unpublished data.

## Common Problems

| Problem | Solution |
|---|---|
| "No GPU found" | Add `-gpu_id 0` or check `nvidia-smi` |
| Simulation crashes after a few ns | Check log for LINCS warnings; try reducing step size |
| Very slow on GPU | Tune `-ntmpi` and `-ntomp`; try `gmx tune_pme` |
| "Out of memory" on GPU | Reduce output frequency or use a smaller box |
| Bond constraint errors (LINCS) | Something is wrong — check if ligand is reasonable |
| SSH disconnected | Use `screen` or `nohup` next time; resume with `-cpi -append` |

## Next Step

```bash
bash scripts/09_analysis.sh
```

See [09_analysis.md](09_analysis.md) for detailed analysis instructions.
