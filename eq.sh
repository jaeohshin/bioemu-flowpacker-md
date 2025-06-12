#!/bin/bash
set -euo pipefail

KINASE=$1
IDX=$2

SRC_PDB="/store/jaeohshin/work/flowpacker/samples/${KINASE}/frame_${IDX}.pdb"
WORKDIR="/store/jaeohshin/work/md_run/${KINASE}/frame_${IDX}"
DOCK_DIR="/store/jaeohshin/work/dock/virtual_screening/input/receptors/${KINASE}"
MDP_DIR="/store/jaeohshin/work/md_run"
FINAL_PDB="${DOCK_DIR}/receptor_${IDX}.pdb"

if [ -f "$FINAL_PDB" ]; then
    echo "[SKIP] Already completed: $FINAL_PDB"
    exit 0
fi

if [ ! -f "$SRC_PDB" ]; then
    echo "[ERROR] Input PDB not found: $SRC_PDB"
    exit 1
fi

mkdir -p "$WORKDIR" "$DOCK_DIR"
cd "$WORKDIR"

echo "[INFO] Starting: ${KINASE} / frame_${IDX}"

# Step 1: Generate topology
gmx pdb2gmx -f "$SRC_PDB" -ignh -o "prot_${IDX}.pdb" -p "topol.top" <<EOF
21
1
EOF

# Step 2: Define box
gmx editconf -f "prot_${IDX}.pdb" -o "prot_box_${IDX}.pdb" -d 1.0 -bt cubic -c

# Step 3: Solvate
gmx solvate -cp "prot_box_${IDX}.pdb" -cs -o "prot_solv_${IDX}.pdb" -p "topol.top"

# Step 4: Add ions
gmx grompp -f "$MDP_DIR/minim.mdp" -c "prot_solv_${IDX}.pdb" -r "prot_solv_${IDX}.pdb" -p "topol.top" -o ions.tpr -maxwarn 40
echo "SOL" | gmx genion -s ions.tpr -o "prot_solv_ions_${IDX}.pdb" -p "topol.top" -neutral -conc 0.15

# Step 5: Energy minimization
gmx grompp -f "$MDP_DIR/minim.mdp" -c "prot_solv_ions_${IDX}.pdb" -r "prot_solv_ions_${IDX}.pdb" -p "topol.top" -o minim.tpr -maxwarn 40
gmx mdrun -s minim.tpr -deffnm "minim_${IDX}" -nt 8 -gpu_id 0

# Step 6: Wrap and center
gmx trjconv -f "minim_${IDX}.gro" -s minim.tpr -pbc mol -ur compact -center -o "minim_whole_${IDX}.pdb" <<EOF
Protein
System
EOF

# Step 6.5: Apply Calpha restraints
gmx select -s "prot_${IDX}.pdb" -select 'name CA' -on ca.ndx
gmx genrestr -f "prot_${IDX}.pdb" -n ca.ndx -o posre_Calpha.itp -fc 10.0 10.0 10.0

cp topol.top topol_nvt.top
sed -i 's/posre\.itp/posre_Calpha.itp/' topol_nvt.top

# Step 7: NVT equilibration
gmx grompp -f "$MDP_DIR/nvt.mdp" -c "minim_whole_${IDX}.pdb" -r "prot_solv_ions_${IDX}.pdb" -p "topol_nvt.top" -o nvt.tpr -maxwarn 40
gmx mdrun -s nvt.tpr -deffnm "nvt_${IDX}" -nt 8 -gpu_id 0

# Step 8: Extract protein
gmx make_ndx -f "nvt_${IDX}.gro" -o "protein_${IDX}.ndx" <<EOF
name 1 Protein
q
EOF

gmx editconf -f "nvt_${IDX}.gro" -o "receptor_${IDX}.pdb" -n "protein_${IDX}.ndx" <<EOF
1
EOF

# Step 9: Copy final receptor
cp "receptor_${IDX}.pdb" "$FINAL_PDB"

echo "[✓] Done: ${KINASE} frame_${IDX} → $FINAL_PDB"

