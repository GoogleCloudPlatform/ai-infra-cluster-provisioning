#!/bin/bash
#
#SBATCH --partition=a3
#SBATCH --exclusive
#SBATCH --gpus-per-node 8
#SBATCH --nodes 4

export MODEL_NAME=                               #'Llama-2-70b-hf'
export GCS_EXPERIMENT_BUCKET=                    # myBucket
export EXPERIMENT_ROOT_DIR=                      # llama-2/training_logs

export UDS_PATH="/run/tcpx-${SLURM_JOB_ID}"

# Configure Docker
srun --ntasks-per-node=1 \
    gcloud auth configure-docker us-central1-docker.pkg.dev

# Launch the litgpt script
srun -l --ntasks-per-node=1 bash litgpt_container.sh
