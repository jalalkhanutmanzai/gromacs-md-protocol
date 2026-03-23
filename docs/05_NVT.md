# 05 — NVT Equilibration

NVT equilibration gradually heats the system from 0 K to the target
temperature (300 K) while keeping the volume constant.  Position restraints
are applied to heavy atoms of the protein and ligand to prevent them moving
while the solvent equilibrates.

---

## Why NVT equilibration is necessary

After energy minimisation the system has no kinetic energy (temperature = 0 K).
Jumping directly to production MD would create an explosive pressure spike.
NVT equilibration:

1. Generates velocities from a Maxwell-Boltzmann distribution at 300 K
2. Thermalises the solvent around the restrained solute
3. Allows bond lengths and angles to relax at the target temperature

---

## 5.1 MDP parameter file (`mdp/nvt.mdp`)

Key parameters:

| Parameter | Value | Meaning |
|---|---|---|
| `integrator` | `md` | Leap-frog MD integrator |
| `dt` | `0.002` | Time step: 2 fs |
| `nsteps` | `50000` | 100 ps total |
| `tcoupl` | `V-rescale` | Velocity-rescaling thermostat |
| `ref_t` | `300 300` | Target temperature for protein+ligand / solvent |
| `tau_t` | `0.1 0.1` | Time constant for thermostat coupling (ps) |
| `pcoupl` | `no` | No pressure coupling during NVT |
| `gen_vel` | `yes` | Generate velocities at start |
| `gen_temp` | `300` | Temperature for velocity generation |
| `gen_seed` | `-1` | Random seed (set in config.env for reproducibility) |
| `define` | `-DPOSRES` | Activate position restraints defined in posre.itp |

---

## 5.2 Pre-process with `grompp`

```bash
source config/config.env

mkdir -p work/04_nvt
cd work/04_nvt

gmx grompp \
    -f ../../mdp/nvt.mdp \
    -c ../03_em/em.gro \
    -r ../03_em/em.gro \
    -p ../01_topology/topol.top \
    -o nvt.tpr \
    -maxwarn 2
```

**Note:** `-r` specifies the reference structure for position restraints
(same as the input coordinates here).

---

## 5.3 Run NVT equilibration

```bash
gmx mdrun \
    -v \
    -deffnm nvt \
    -gpu_id ${GPU_ID:-0} \
    -ntmpi 1 \
    -ntomp ${NTOMP:-4}
```

NVT equilibration (100 ps) completes in approximately **5–15 minutes**
on a V100S GPU.

---

## 5.4 Check temperature convergence

```bash
printf "Temperature\n0\n" | gmx energy \
    -f nvt.edr \
    -o temperature.xvg
```

The temperature should rise from near 0 K and stabilise around 300 K within
the first 20–30 ps.  A flat, fluctuating plateau at 300 ± 5 K indicates
good convergence.

---

## 5.5 Run the automated script

```bash
bash scripts/04_nvt.sh
```

Output files (in `work/04_nvt/`):

| File | Description |
|---|---|
| `nvt.tpr` | Binary run-input file |
| `nvt.gro` | Final coordinates after NVT |
| `nvt.cpt` | Checkpoint file (for restarting) |
| `nvt.edr` | Energy trajectory |
| `nvt.log` | Log file |

---

## 5.6 Restarting a crashed NVT run

If the run crashes or times out, restart from the last checkpoint:

```bash
cd work/04_nvt
gmx mdrun \
    -v \
    -deffnm nvt \
    -cpi nvt.cpt \
    -gpu_id ${GPU_ID:-0} \
    -ntmpi 1 \
    -ntomp ${NTOMP:-4}
```

The `-cpi` flag instructs GROMACS to read and continue from the checkpoint.
