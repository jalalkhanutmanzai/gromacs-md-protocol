# 07 — Production MD

The production MD run generates the trajectory that you will analyse.
Position restraints are removed, and the system evolves freely under the
chosen ensemble (NPT at 300 K, 1 bar).

---

## 7.1 MDP parameter file (`mdp/md_100ns.mdp`)

Key parameters:

| Parameter | Value | Meaning |
|---|---|---|
| `integrator` | `md` | Leap-frog integrator |
| `dt` | `0.002` | Time step: 2 fs |
| `nsteps` | `50000000` | 100 ns total (50 M × 2 fs) |
| `tcoupl` | `V-rescale` | Thermostat |
| `ref_t` | `300 300` | Target temperature |
| `pcoupl` | `Parrinello-Rahman` | Barostat |
| `ref_p` | `1.0` | Target pressure |
| `continuation` | `yes` | Continue from NPT |
| `gen_vel` | `no` | Velocities from NPT checkpoint |
| `nstxout` | `0` | Write to TRR (binary): disabled (use compressed) |
| `nstvout` | `0` | Write velocities: disabled |
| `nstfout` | `0` | Write forces: disabled |
| `nstxout-compressed` | `5000` | Write XTC every 5000 steps = every 10 ps |
| `nstenergy` | `5000` | Write energies every 10 ps |
| `nstlog` | `5000` | Write to log every 10 ps |
| `define` | (empty) | No position restraints |

---

## 7.2 Pre-process with `grompp`

```bash
source config/config.env

mkdir -p work/06_md
cd work/06_md

gmx grompp \
    -f ../../mdp/md_100ns.mdp \
    -c ../05_npt/npt.gro \
    -t ../05_npt/npt.cpt \
    -p ../01_topology/topol.top \
    -o md.tpr \
    -maxwarn 2
```

---

## 7.3 Run production MD locally

```bash
gmx mdrun \
    -v \
    -deffnm md \
    -gpu_id ${GPU_ID:-0} \
    -ntmpi 1 \
    -ntomp ${NTOMP:-4} \
    -pin on
```

**`-pin on`** enables CPU thread pinning for better performance.

Expected performance on a V100S GPU: **~50–100 ns/day** depending on system
size.  100 ns therefore takes **1–2 days**.

---

## 7.4 Run on HPC via SLURM

Edit and submit the SLURM template:

```bash
cp templates/slurm/gmx_gpu.slurm my_job.slurm
# Edit: partition, account, time, GPU count
sbatch my_job.slurm
```

See `templates/slurm/gmx_gpu.slurm` for comments on mapping SLURM resources
to `gmx mdrun` flags.

Monitor job status:

```bash
squeue -u $USER
sacct -j <JOBID> --format=JobID,Elapsed,State,ExitCode
```

---

## 7.5 Restarting a crashed or timed-out production run

GROMACS writes checkpoint files (`.cpt`) every 15 minutes by default.
To continue:

```bash
cd work/06_md
gmx mdrun \
    -v \
    -deffnm md \
    -cpi md.cpt \
    -gpu_id ${GPU_ID:-0} \
    -ntmpi 1 \
    -ntomp ${NTOMP:-4} \
    -pin on
```

No data is lost; the trajectory file (`.xtc`) is extended from where
the run stopped.

---

## 7.6 Run the automated script

```bash
bash scripts/06_md.sh
```

Output files (in `work/06_md/`):

| File | Description |
|---|---|
| `md.tpr` | Binary run-input file |
| `md.xtc` | Compressed trajectory (10 ps/frame) |
| `md.edr` | Energy trajectory |
| `md.cpt` | Latest checkpoint |
| `md.log` | Log file |

> All of these are gitignored — they must not be committed.

---

## 7.7 Checking run progress

```bash
# How far has the run progressed?
grep "^Performance" work/06_md/md.log | tail -1

# See last few log lines
tail -30 work/06_md/md.log
```
