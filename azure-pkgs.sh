#!/bin/bash
################################################################################
#
# Spack Package Installation Script for Azure CentOS HPC Images
# Author Mike Kiernan, Microsoft
# Tested On: CentOS-HPC 7.6 & 7.7
# PREREQ: make sure you've installed spack with azure-spack.sh first
#
################################################################################
# KNOWN ISSUES:
# 1) Anything using Intel MPI 2019 must be built with -dirty to pickup libfabric
#    from the modulefile until intel-mpi spack package is fixed for 2019/2020
# 2) HPCX package is waiting on a fix to source the built-in modulefile
# 3) Intel MPI 2018 & 2019 support up to gcc@8.2.0 (mainly for fortran 
#    dependent builds like hdf5)
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
    %gcc@8.2.0
    %gcc@9.2.0
    %intel@18.0.5
    %intel@19.0.5
)
#-- mpi: use the Azure CentOS HPC image pre-installed modules were possible - see packages.yaml
#-- using azure modules: openmpi, mvpich2
#-- using builtin spack: mpich (or perhaps consider mpich deprecated and leave it hashed out). 
#-- broken: hpcx@2.5.0 & intel-mpi@2019 (issues open on spack github)
mpis=(
    openmpi@4.0.2
    mvapich2@2.3.2
    intel-mpi@2018.4.274
#    intel-mpi@2019.5.281
    mpich@3.3.2
)
mkls=(
    intel-mkl@2019.5.281
    intel-mkl@2018.4.274
)
declare -A foundations=(
    [libszip@2.1.1]=serial
    [hdf5@1.10.5]=parallel
    [netcdf-c@4.7.3]=parallel
    [netcdf-fortran@4.5.2]=parallel
)
declare -A benchmarks=(
    [stream@5.10]=serial
    [osu-micro-benchmarks@5.6.2]=parallel
    [ior@3.2.0]=parallel
    [hpl@2.3]=parallel
)
declare -A quantum_espresso=(
    [elpa@2019.05.002]=parallel
    [quantum-espresso@6.5]=parallel
)

#-- apply these only to specific codes
arch=`spack arch -t`
if [[ "$arch" == "zen" || "$arch" == "zen2" ]]; then 
   #opt='cflags="-O3 -march=core-avx2" cxxflags="-O3 -march=core-avx2" fflags="-O3 -march=core-avx2"'
   opt="cflags='-O3 -march=core-avx2' cxxflags='-O3 -march=core-avx2' fflags='-O3 -march=core-avx2'"
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

    #-- install additional compiler as intel-mpi 2018 is stuck at gcc@8.2.0
    #-- can't build hdf5/netcdf with intel-mpi@2018 & >gcc@8.2.0
    cmd="spack install gcc@8.2.0"; execho "$cmd"
    cmd="spack load gcc@8.2.0"; execho "$cmd"
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
        cmd="spack install $mpi $compiler"; execho "$cmd" 
    done
    if [ $dryrun -eq 0 ]; then functiontimer "install_mpis()"; fi

} #-- end of install_mpis() --#

install_mathlibs()
{
    echo "############## mathlib packages ##################"
    #-- installing mpi's only for default gcc@9.2.0
    compiler="%gcc@9.2.0"
    for mkl in "${mkls[@]}"
    do
        cmd="spack install $mkl $compiler"; execho "$cmd"
    done
    if [ $dryrun -eq 0 ]; then functiontimer "install_mathlibs()"; fi

} #-- end of install_mathlibs() --#

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
                   cmd="spack install $benchmark $compiler $opt ^$mpi"; execho "$cmd"
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
           for mkl in "${mkls[@]}"
           do
               info "$compiler && $mpi && $mkl"
               cmd="spack install elpa@2019.05.002 $compiler $opt ^$mkl ^$mpi"; execho "$cmd"
               cmd="spack install quantum-espresso@6.5 $compiler $opt +elpa+scalapack ^$mkl ^$mpi"; execho "$cmd"
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
install_foundation_libraries
install_microbenchmarks
install_quantum_espresso

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
