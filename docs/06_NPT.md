# 06 — NPT Equilibration

NPT equilibration maintains constant temperature and pressure, allowing the
simulation box volume to adjust until the system density converges.

---

## Why NPT equilibration is necessary

After NVT, the system is at the correct temperature but the density may be
slightly off (because the box volume was fixed).  NPT equilibration:

1. Turns on pressure coupling (barostat)
2. Allows the box to expand or contract until the pressure stabilises at 1 bar
3. Establishes the correct density for the production run

---

## 6.1 MDP parameter file (`mdp/npt.mdp`)

Key parameters:

| Parameter | Value | Meaning |
|---|---|---|
| `integrator` | `md` | Leap-frog MD integrator |
| `dt` | `0.002` | Time step: 2 fs |
| `nsteps` | `50000` | 100 ps total |
| `tcoupl` | `V-rescale` | Velocity-rescaling thermostat |
| `ref_t` | `300 300` | Target temperature (K) |
| `pcoupl` | `Parrinello-Rahman` | Barostat (best for production-quality NPT) |
| `ref_p` | `1.0` | Target pressure: 1 bar |
| `tau_p` | `2.0` | Barostat time constant (ps) |
| `compressibility` | `4.5e-5` | Isothermal compressibility of water (bar⁻¹) |
| `continuation` | `yes` | Continue from NVT; do NOT regenerate velocities |
| `gen_vel` | `no` | Velocities come from NVT checkpoint |
| `define` | `-DPOSRES` | Keep position restraints active |

---

## 6.2 Pre-process with `grompp`

```bash
source config/config.env

mkdir -p work/05_npt
cd work/05_npt

gmx grompp \
    -f ../../mdp/npt.mdp \
    -c ../04_nvt/nvt.gro \
    -r ../04_nvt/nvt.gro \
    -t ../04_nvt/nvt.cpt \
    -p ../01_topology/topol.top \
    -o npt.tpr \
    -maxwarn 2
```

**Flags explained:**

| Flag | Meaning |
|---|---|
| `-c` | Input coordinates: final NVT frame |
| `-r` | Reference for position restraints |
| `-t` | Checkpoint from NVT (provides velocities) |

---

## 6.3 Run NPT equilibration

```bash
gmx mdrun \
    -v \
    -deffnm npt \
    -gpu_id ${GPU_ID:-0} \
    -ntmpi 1 \
    -ntomp ${NTOMP:-4}
```

NPT equilibration (100 ps) typically completes in **5–15 minutes** on a GPU.

---

## 6.4 Check pressure and density convergence

```bash
# Pressure
printf "Pressure\n0\n" | gmx energy \
    -f npt.edr \
    -o pressure.xvg

# Density
printf "Density\n0\n" | gmx energy \
    -f npt.edr \
    -o density.xvg
```

Expected values at equilibrium:
- Pressure: ~1 bar (fluctuates ±100 bar — this is normal)
- Density: ~1000 kg m⁻³ (water density)

---

## 6.5 Run the automated script

```bash
bash scripts/05_npt.sh
```

Output files (in `work/05_npt/`):

| File | Description |
|---|---|
| `npt.tpr` | Binary run-input file |
| `npt.gro` | Final coordinates after NPT |
| `npt.cpt` | Checkpoint file |
| `npt.edr` | Energy trajectory |
| `npt.log` | Log file |

---

## 6.6 Restarting a crashed NPT run

```bash
cd work/05_npt
gmx mdrun \
    -v \
    -deffnm npt \
    -cpi npt.cpt \
    -gpu_id ${GPU_ID:-0} \
    -ntmpi 1 \
    -ntomp ${NTOMP:-4}
```
