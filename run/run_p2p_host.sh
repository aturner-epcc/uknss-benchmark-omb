#!/bin/bash
#SBATCH --job-name=OMB_p2p_host
#SBATCH --output=OMB_p2p_host-%j.out 
#SBATCH --exclusive
#SBATCH --nodes=2
#SBATCH --time=00:30:00
#SBATCH --gpus-per-node=4
#SBATCH -w nid[010001,011317]
#
#The -w option specifies which nodes to use for the test,
#thus controlling the number of network hops between them.
#It should be modified for each system because
#the nid-topology differs with the system architecture.

#The number of NICs(j) and CPU cores (k) per node
#should be specified here.
j=4   #NICs per node
jstride=72 # Stride of tasks between NICs
k=288 #Cores per node
twostride=144 # Stride of tasks for 2-task tests

# Specify any additional Slurm options
srunopts="--hint=nomultithread --distribution=block:block"

#The paths to OMB and its point-to-point benchmarks
#should be specified here
OMB_DIR=/projects/u6cb/benchmarks/OSU/7.5.2-gcc-cpu/libexec/osu-micro-benchmarks
OMB_PT2PT=${OMB_DIR}/mpi/pt2pt
OMB_1SIDE=${OMB_DIR}/mpi/one-sided

module load craype-network-ofi
module load PrgEnv-gnu 
module load gcc-native/13.2 
module load cray-mpich
module load craype-arm-grace
module load cray-python
module load cray-fftw

srun ${srunopts} --nodes=2 --ntasks=2 --cpus-per-task=${twostride} \
     ${OMB_PT2PT}/osu_latency -m 8:8 

srun ${srunopts} --nodes=2 --ntasks=2  --cpus-per-task=${twostride} \
     ${OMB_PT2PT}/osu_bibw -m 1048576:1048576

srun ${srunopts} --nodes=2 --ntasks-per-node=${j} --cpus-per-task=${jstride} \
     ${OMB_PT2PT}/osu_mbw_mr -m 16384:16384

srun ${srunopts} --nodes=2 --ntasks-per-node=${k} \
     ${OMB_PT2PT}/osu_mbw_mr -m 16384:16384

srun ${srunopts} --nodes=2 --ntasks=2 --cpus-per-task=${twostride} \
     ${OMB_1SIDE}/osu_get_acc_latency -m 8:8 

