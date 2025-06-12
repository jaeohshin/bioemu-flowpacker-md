#!/bin/bash
#SBATCH --job-name=eq_all
#SBATCH --output=logs/eq_%A_%a.out
#SBATCH --error=logs/eq_%A_%a.err
#SBATCH --array=0-99%10         # adjust range & concurrency
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --time=24:00:00
#SBATCH --partition=normal

# Load job list
mapfile -t JOBS < /store/jaeohshin/work/md_run/job_list.tsv
JOB="${JOBS[$SLURM_ARRAY_TASK_ID]}"

KINASE=$(echo "$JOB" | cut -f1)
INDEX=$(echo "$JOB" | cut -f2)

bash /store/jaeohshin/work/md_run/eq.sh "$KINASE" "$INDEX"
