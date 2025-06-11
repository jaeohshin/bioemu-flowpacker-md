# bioemu-flowpacker-md

A pipeline for generating MD-relaxed protein conformational ensembles for docking.

This project automates the preparation of diverse protein structures using:
- **BioEmu** for backbone ensemble generation
- **FlowPacker** for sidechain reconstruction
- **GROMACS** for molecular dynamics-based structural relaxation

The final output is a set of docking-ready `.pdb` files representing conformational diversity of the input protein sequence (e.g., kinases).

---

## 📌 Workflow Overview

sequence.fasta
↓ BioEmu
topology.pdb + sample.xtc
↓ FlowPacker
sidechain-packed PDBs
↓ GROMACS
relaxed docking-ready structures

---

## 📁 Directory Structure
bioemu-flowpacker-md/
├── stage1_generation/
│ ├── run_generation.sh
│ ├── sequence.fasta
│ ├── bioemu_config.yaml
│ ├── flowpacker_config.yaml
│ └── sidechain_pdbs/
├── stage2_relaxation/
│ ├── run_relaxation.sh
│ ├── mdp/
│ │ ├── minim.mdp
│ │ ├── nvt.mdp
│ │ └── npt.mdp
│ ├── relaxed_pdbs/
│ └── xtc_to_pdb.py
├── utils/
│ └── extract_n_structures.py
└── README.md


---

## 🔧 Dependencies

- Python 3.8+
- [BioEmu](https://github.com/ProteinDesignLab/BioEmu)
- [FlowPacker](https://github.com/ProteinDesignLab/FlowPacker)
- [GROMACS](https://www.gromacs.org/)
- PyMOL / MDAnalysis / MDTraj (optional, for analysis)

---

## 🚀 Usage

### 1. Backbone & Sidechain Generation
```bash
cd stage1_generation
bash run_generation.sh  # Runs BioEmu + FlowPacker

cd stage2_relaxation
bash run_relaxation.sh  # Can be submitted as SLURM array job

python xtc_to_pdb.py --xtc sample.xtc --top topology.pdb --outdir relaxed_pdbs/

🧬 Example Use Case

This pipeline was used to generate 100 relaxed structural conformations for 25 kinases, later used as receptor ensembles for virtual screening with AutoDock-GPU.

