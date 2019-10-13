#!/bin/bash
SPACKROOT=`pwd`
git clone https://github.com/spack/spack.git
# hack for missing clzero flg on HB60rs https://github.com/spack/spack/issues/12896
pushd spack/lib/spack/llnl/util/cpu/
sed --in-place=.org '/\"clzero\",/d' microarchitectures.json
popd

#-- set build_jobs to 32
#-- edit this with "spack config --scope defaults edit config"
pushd spack/etc/spack/defaults/
sed --in-place=.org 's/\# build_jobs: 16/build_jobs: 32/g' config.yaml
popd

mkdir -p ~/.spack/linux
wget https://raw.githubusercontent.com/mkiernan/azure-spack/master/compilers.yaml
wget https://raw.githubusercontent.com/mkiernan/azure-spack/master/packages.yaml
cp compilers.yaml ~/.spack/linux
cp packages.yaml ~/.spack

#-- setup env
echo ". ${SPACKROOT}/spack/share/spack/setup-env.sh" >> ~/.bashrc
source ~/.bashrc
