#!/bin/bash
#SBATCH --job-name=OMB_p2p_accel
#SBATCH --output=OMB_p2p_accel-%j.out
#SBATCH --nodes=2
#SBATCH -t 00:30:00
#SBATCH --gpus-per-node=4
##SBATCH -w nid[001652,001716]
#
#The -w option specifies which nodes to use for the test,
#thus controling the number of network hops between them.
#It should be modified for each system because
#the nid-topology differs with the system architechture.

#The number of NICs(j) and accelrators(a) per node
#should be specified here.
j=4 #NICs per node
a=4 #accelerator devices per node

#The paths to OMB and its point-to-point benchmarks
#should be specified here
OMB_DIR=/projects/u6cb/benchmarks/OSU/7.5.2-gpu-cuda/libexec/osu-micro-benchmarks
OMB_PT2PT=${OMB_DIR}/mpi/pt2pt
OMB_1SIDE=${OMB_DIR}/mpi/one-sided

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

srun --nodes=2 --ntasks=2 \
     ${OMB_DIR}/get_local_rank \
     ${OMB_PT2PT}/osu_latency -m 8:8 -x 0 D D

srun --nodes=2 --ntasks=2  \
     ${OMB_DIR}/get_local_rank \
     ${OMB_PT2PT}/osu_bw -m 1048576:1048576 -x 0 D D

srun --nodes=2 --ntasks-per-node=${j} \
     ${OMB_DIR}/get_local_rank  \
     ${OMB_PT2PT}/osu_mbw_mr -m 16384:16384 -x 0 D D

srun --nodes=2 --ntasks-per-node=${a} \
     ${OMB_DIR}/get_local_rank  \
     ${OMB_PT2PT}/osu_mbw_mr -m 16384:16384 -x 0 D D

srun --nodes=2 --ntasks=2 \
     ${OMB_DIR}/get_local_rank \
     ${OMB_1SIDE}/osu_get_acc_latency -m 8:8 -x 0 D D 
