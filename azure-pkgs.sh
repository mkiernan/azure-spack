#!/bin/bash 

#-- ensure spack env is set
source ~/.bashrc 

#-- compilers
ARCH=`spack arch`
spack compilers
spack install gcc@8.2.0  #-- already in /opt - see packages.yaml/compilers.yaml
spack install gcc@9.2.0
spack load gcc@9.2.0 arch=${ARCH}
spack compiler find

#-- mpi: use the Azure CentOS HPC image pre-installed modules - see packages.yaml
spack install openmpi@4.0.1%gcc@8.2.0
spack install mvapich2@2.3.1%gcc@8.2.0
spack install intel-mpi@2018.4.274%gcc@8.2.0
spack install mpich@3.3%gcc@8.2.0

#-- micro benchmarks
spack install stream@5.10%gcc@9.2.0+openmp
spack install osu-micro-benchmarks@5.6.1%gcc@8.2.0 ^intel-mpi@2018.4.274%gcc@8.2.0 
spack install ior@3.2.0%gcc@8.2.0+hdf5 ^intel-mpi@2018.4.274%gcc@8.2.0
spack install hpl@2.3%gcc@8.2.0+openmp ^intel-mkl@2018.4.274%gcc@8.2.0 ^intel-mpi@2018.4.274%gcc@8.2.0

#-- netcdf & hdf5
spack install parallel-netcdf@1.11.2%gcc@8.2.0+cxx+fortran+pic ^intel-mpi@2018.4.274%gcc@8.2.0
spack install hdf5@1.10.5%gcc@8.2.0+cxx+fortran+mpi+pic+shared+szip+threadsafe ^intel-mpi@2018.4.274%gcc@8.2.0

#-- quantum espresso : intelmpi, elpa
spack install elpa@2018.11.001%gcc@8.2.0 ^intel-mkl@2018.4.274%gcc@8.2.0 ^intel-mpi@2018.4.274%gcc@8.2.0
spack install quantum-espresso@6.4.1%gcc@8.2.0+elpa hdf5=parallel +openmp+scalapack+mpi ^intel-mkl@2018.4.274%gcc@8.2.0 ^intel-mpi@2018.4.274%gcc@8.2.0 

#-- quantum espresso : mvapich2, elpa
spack install elpa@2018.11.001%gcc@8.2.0 ^intel-mkl@2018.4.274%gcc@8.2.0 ^mvapich2@2.3.1%gcc@8.2.0
spack install quantum-espresso@6.4.1%gcc@8.2.0+elpa hdf5=parallel +openmp+scalapack+mpi ^intel-mkl@2018.4.274%gcc@8.2.0 ^mvapich2@2.3.1%gcc@8.2.0

#-- quantum espresso : openmpi, mkl 
spack install quantum-espresso@6.4.1%gcc@8.2.0 ^intel-mkl@2018.4.274%gcc@8.2.0 ^openmpi@4.0.1%gcc@8.2.0



