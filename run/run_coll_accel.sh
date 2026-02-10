#!/bin/bash
#SBATCH --job-name=OMB_coll_accel
#SBATCH --output=OMB_coll_accel-%j.out
#SBATCH --exclusive
#SBATCH --nodes=512
#SBATCH --time=00:30:00
#SBATCH --gpus-per-node=4
#
#The --nodes option should be updated
#to use the full-system complement of accelerated nodes

#The number of NICs(j)
#should be specified here
j=4 #NICs per node
jstride=72 # Stride of tasks between NICs

# Specify any additional Slurm options
srunopts="--hint=nomultithread --distribution=block:block"

#The paths to OMB and its collective benchmarks
#should be specified here
OMB_DIR=/projects/u6cb/benchmarks/OSU/7.5.2-gcc-cuda/libexec/osu-micro-benchmarks
OMB_COLL=${OMB_DIR}/mpi/collective

#Compute the total number of tasks 
#to run on the full system (n_any),
#and the next smaller odd number (n_odd)
N_any=$(( SLURM_JOB_NUM_NODES     ))
n_any=$(( SLURM_JOB_NUM_NODES * j ))
N_odd=$N_any
n_odd=$n_any
if [ $(( n_any % 2 )) -eq 0 ]; then
    n_odd=$(( n_any - 1 ))
    if [ $j -eq 1 ]; then
	N_odd=$n_odd
    fi
fi

module load craype-network-ofi
module load PrgEnv-gnu 
module load gcc-native/13.2 
module load cray-mpich
module load cuda/12.6
module load craype-accel-nvidia90
module load craype-arm-grace
module load cray-python
module load cray-fftw

export MPICH_GPU_SUPPORT_ENABLED=1

echo -n Nodes:$N_any   Tasks:$n_any
srun ${srunopts} --nodes=${N_any} --ntasks=${n_any} --ntasks-per-node=${j} --cpus-per-task=${jstride} \
     ${OMB_DIR}/get_local_rank  \
     ${OMB_COLL}/osu_allreduce -m 8:8 -d cuda
echo

echo -n Nodes:$N_any   Tasks:$n_any
srun ${srunopts} --nodes=${N_any} --ntasks=${n_any} --ntasks-per-node=${j} --cpus-per-task=${jstride} \
     ${OMB_DIR}/get_local_rank  \
     ${OMB_COLL}/osu_allreduce -m 26214400:26214400 -d cuda
echo

echo -n Nodes:$N_odd   Tasks:$n_odd
srun ${srunopts} --nodes=${N_odd} --ntasks=${n_odd} --ntasks-per-node=${j} --cpus-per-task=${jstride} \
     ${OMB_DIR}/get_local_rank \
     ${OMB_COLL}/osu_alltoall -m 1048576:1048576 -d cuda
echo

