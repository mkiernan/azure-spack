#!/bin/bash
################################################################################
#
# Spack Package Installation Script for Azure CentOS HPC Images
# Author Mike Kiernan, Microsoft
# Tested On: CentOS-HPC 7.9
# PREREQ: make sure you've installed spack with azure-spack.sh first
#
################################################################################
# KNOWN ISSUES:
################################################################################

#-- ensure spack env is set
source ~/.bashrc 

usage()
{
    echo -e "\nUsage: $(basename $0) [--silent,-s <non-interactive mode: for automated installs.>]\n"
    echo -e "eg: $(basename $0) --silent\n"
    exit 1
} #-- end of usage() --#

silent=0; dryrun=1 #-- default to interactive

while [[ $# -gt 0 ]]
do
   key="$1"
   case $key in
     -s|--silent)
     silent=1; dryrun=0
     shift; shift
     ;;
     *)
     usage
     ;;
   esac
done

function goto { eval "$(sed -n "/$1:/{:a;n;p;ba};" $0 |grep -v ':$')";exit;};start=${1:-"start"}; goto $start

start: 
#-- script and all globals start here

function red { echo -e "\033[31;7m$1\e[0m"; }  #-- red
function green { echo -e "\033[32;7m$1\e[0m"; } #-- green
function amber { echo -e "\033[33;7m$1\e[0m"; } #-- amber
function info { echo -e "\033[36;7m$1\e[0m"; } #-- cyan

if [ $dryrun -eq 1 ]; then
      info "*** THIS IS A DRY RUN ***"
   else 
      info "*** LIVE INSTALLATION STARTING ***"
fi
#-- global counters
pass=0; fail=0
declare -a passed
declare -a failed
################################################################################
#  ADMINISTRATOR/USER EDITABLE SECTION: Change versions required here
################################################################################
#-- note: just hash out the lines you don't want
#-- duplicate lines if you want multiple package versions
compilers=(
    %gcc@9.2.0
#    %aocc@3.2.0
#    %intel@18.0.5
#    %intel@19.0.5
)
#-- mpi: use the Azure HPC image pre-installed modules were possible - see packages.yaml
#-- using azure modules from /opt: openmpi, mvapich2, hpcx, intelmpi
mpis=(
#    openmpi@4.1.0
#    mvapich2@2.3.5
    intel-mpi@2018.4.274
#   intel-mpi@2021.2.0
    hpcx-mpi@2.8.3
#   mpich@3.3.2
)

maths=(
     intel-mkl@2020.4.304
     amdblis@3.1 #-- gcc@9.2.0 install for hpl+hpcx
)

declare -A foundations=(
    [libszip@2.1.1]=serial
    [hdf5@1.12.1]=parallel
    [netcdf-c@4.8.1]=parallel
    [netcdf-fortran@4.5.3]=parallel
)
declare -A benchmarks=(
    [stream@5.10]=serial
    [osu-micro-benchmarks@5.7.1]=parallel
    [ior@3.3.0]=parallel
    [hpl@2.3]=parallel
)
declare -A quantum_espresso=(
    [elpa@2021.11.001]=parallel
    [quantum-espresso@7.0]=parallel
)

#-- apply these only to specific codes
arch=`spack arch -t`
#if [[ "$arch" == "zen" || "$arch" == "zen2" ]]; then 
if [ "$arch" == "zen" ]; then 
   #opt='cflags="-O3 -march=core-avx2" cxxflags="-O3 -march=core-avx2" fflags="-O3 -march=core-avx2"'
   #opt="cflags='-O3 -march=core-avx2' cxxflags='-O3 -march=core-avx2' fflags='-O3 -march=core-avx2'"
   #-- gcc options
   #opt="cflags='-O3 -march=native -fopenmp' cxxflags='-O3 -march=native -fopenmp' fflags='-O3 -march=native -fopenmp'"
   opt="cflags='-O3 -march=znver1 -fopenmp' cxxflags='-O3 -march=znver1 -fopenmp' fflags='-O3 -march=znver1 -fopenmp'"
elif [ "$arch" == "zen2" ]; then 
   #opt="cflags='-O3 -march=znver2 -fopenmp' cxxflags='-O3 -march=znver2 -fopenmp' fflags='-O3 -march=znver2 -fopenmp'"
   opt="cflags='-O3 -march=native -fopenmp' cxxflags='-O3 -march=native -fopenmp' fflags='-O3 -march=native -fopenmp'"
elif [ "$arch" == "skylake" ]; then
   opt='cflags="-O3 -march=skylake-avx512 -mtune=skylake-avx512"'
fi
amber "optimization for $arch: $opt"

################################################################################
# END ADMINISTRATOR/USER EDITABLE SECTION
################################################################################

SECONDS=0 #-- use builtin shell var to record function times
WALLTIME=0 #-- record wall time of script
functiontimer()
{
    echo "Function $1 took $SECONDS seconds";
    let WALLTIME+=$SECONDS
    SECONDS=0

} #--- end of functiontimer() ---#

#-- execute & echo full command so we can re-run by hand if needed. 
execho()
{
    cmd=$1
    #echo -e "\033[32;7m$cmd\e[0m";
    green "$cmd"
    if [ $dryrun -eq 0 ]; then
        $cmd
        rc=$?
        if [ $rc -eq 0 ]; then
           #passed[$pass] = "$cmd"
           passed+=("$cmd")
           pass=$((pass+1))
        else
           #failed[$fail] = "$cmd"
           failed+=("$cmd")
           fail=$((fail+1))
        fi
        if [ $fail -gt 0 ]; then
            amber "pass: $pass, fail: $fail"
        else
            info "pass: $pass, fail: $fail"
        fi
    fi

} #-- end of execho() --#

install_compilers()
{
    echo "################## compilers ######################"
    #ARCH=`spack arch`
    #spack load gcc@9.2.0 arch=${ARCH}

    #-- install AMD compiler from spack package 
    AWD=`pwd`
    spack install aocc@3.2.0 
    spack cd -i aocc@3.2.0
    spack compiler add $PWD
    cd $AWD

    cmd="spack compiler find"; execho "$cmd"
    if [ $dryrun -eq 0 ]; then spack compilers; fi
    if [ $dryrun -eq 0 ]; then functiontimer "install_compilers()"; fi

} #-- install_compilers() --#

install_mpis()
{
    echo "################ mpi packages ####################"
    #-- installing mpi's only for default gcc@9.2.0
    compiler="%gcc@9.2.0"
    for mpi in "${mpis[@]}"
    do
        cmd="spack install $mpi $compiler $opt"; execho "$cmd" 
    done
    if [ $dryrun -eq 0 ]; then functiontimer "install_mpis()"; fi

} #-- end of install_mpis() --#

install_mathlibs()
{
    echo "############## mathlib packages ##################"
    #-- installing mpi's only for default gcc@9.2.0
    compiler="%gcc@9.2.0"
    for mathlib in "${maths[@]}"
    do
        cmd="spack install $mathlib $compiler $opt"; execho "$cmd"
    done
    if [ $dryrun -eq 0 ]; then functiontimer "install_mathlibs()"; fi

} #-- end of install_mathlibs() --#

install_amdlibs()
{
    #-- https://developer.amd.com/spack/amd-optimized-cpu-libraries/
    compiler="%aocc@3.2.0"
    echo "############# amd aocl packages ##################"
    cmd="spack install amdblis@3.1 $compiler"; execho "$cmd"
    cmd="spack install amdlibflame@3.1 ^amdblis@3.1 $compiler"; execho "$cmd"
    cmd="spack install amdfftw@3.1+amd-fast-planner precision=float,double $compiler"; execho "$cmd"
    cmd="spack install amdscalapack@3.1 ^amdblis@3.1 ^amdlibflame@3.1 $compiler"; execho "$cmd"
    cmd="spack install amdlibm@3.1 $compiler"; execho "$cmd"
    cmd="spack install aocl-sparse@3.1 $compiler"; execho "$cmd"

    if [ $dryrun -eq 0 ]; then functiontimer "install_amdlibs()"; fi

} #-- end of install_amdlibs() --#

install_microbenchmarks()
{
    echo "############### benchmark packages ###############"
    for compiler in "${compilers[@]}"
    do
       #-- serial (no mpi)
       info "$compiler"
       for benchmark in "${!benchmarks[@]}"; do
           if [ ${benchmarks[$benchmark]} == "serial" ]; then
                cmd="spack install $benchmark $compiler $opt"; execho "$cmd"
           fi
       done
       #-- parallel (with mpi)
       for mpi in "${mpis[@]}"
       do
           info "$compiler && $mpi"
           for benchmark in "${!benchmarks[@]}"; do
               if [ ${benchmarks[$benchmark]} == "parallel" ]; then
                   #-- hpl with hpcx does not work with mkl, so use amdblis 
                   if [ $benchmark == "hpl@2.3" ] && [ $mpi == hpcx-mpi@2.8.3 ]; then
                        cmd="spack install $benchmark $compiler $opt ^$mpi ^amdblis@3.1"; execho "$cmd"
                   else 
                        cmd="spack install $benchmark $compiler $opt ^$mpi"; execho "$cmd"
                   fi
               fi
           done
       done
    done
    if [ $dryrun -eq 0 ]; then functiontimer "install_microbenchmarks()"; fi

} #-- end of install_microbenchmarks() --#

install_foundation_libraries()
{
    echo "############## hdf5/netcdf packages ##############"
    for compiler in "${compilers[@]}"
    do
       #-- serial (no mpi)
       info "$compiler"
       for library in "${!foundations[@]}"; do
           if [ ${foundations[$library]} == "serial" ]; then
                cmd="spack install $library $compiler $opt"; execho "$cmd"
           fi
       done
       #-- parallel (with mpi)
       for mpi in "${mpis[@]}"
       do
           info "$compiler && $mpi"
           for library in "${!foundations[@]}"; do
               if [ ${foundations[$library]} == "parallel" ]; then
                   cmd="spack install $library $compiler $opt ^$mpi"; execho "$cmd"
               fi
           done
       done
    done
    if [ $dryrun -eq 0 ]; then functiontimer "install_foundation_libraries()"; fi

} #-- end of install_foundation_libraries() --#

install_quantum_espresso()
{
    echo "############## quantum espresso ##############"
    for compiler in "${compilers[@]}"
    do
       for mpi in "${mpis[@]}"
       do
           for mathlib in "${maths[@]}"
           do
               info "$compiler && $mpi && $mathlib"
               cmd="spack install elpa@2019.05.002 $compiler $opt ^$mathlib ^$mpi"; execho "$cmd"
               cmd="spack install quantum-espresso@6.5 $compiler $opt +elpa+scalapack ^$mathlib ^$mpi"; execho "$cmd"
           done
       done
    done
    if [ $dryrun -eq 0 ]; then functiontimer "install_quantum_espresso()"; fi

} #-- install_quantum_espresso() --#

summarize()
{
    echo "$pass commands succeeded:"
    for cmd in "${passed[@]}"
    do
        green "$cmd"
    done
   
    echo "$fail commands failed:"
    for cmd in "${failed[@]}"
    do
        red "$cmd"
    done
    echo "###################### complete ######################"
    if [ $dryrun -eq 0 ]; then echo "Script ran for $WALLTIME seconds."; fi

    if [ $fail -ne 0 ]; then 
       exit 1
    else
       exit 0
    fi

} #-- end of summarize() --#

################################################################################
# MAIN PROGRAM 
################################################################################
install_compilers
install_mpis
install_mathlibs
#install_amdlibs
install_microbenchmarks
install_foundation_libraries
#install_quantum_espresso

#-- if live run complete, summarize & exit
if [ $dryrun -eq 0 ]; then summarize; fi

#-- if running in interactive mode, challenge before installing
if [ $silent -eq 0 ]; then
     info "                *** DRY RUN COMPLETE ***                 "
     read -n 1 -p "Do you want to execute? [Y/n] " ans; echo
     if [ "$ans" != "${ans#[Yy]}" ]; then
           echo "$(basename $0): executing install..."
           dryrun=0
           goto start
     fi
else 
     dryrun=0
     goto start
fi
