# azure-spack

Setup scripts to get <a href="https://spack.readthedocs.io">Spack</a> running on the Azure HC44rs/HB60rs/HB120rs_v2 HPC platforms. These scripts are designed to be run on the Azure OpenLogic:CentOS-HPC:7.6 & 7.7:latest operating system images, which come with all SR-IOV ready MPI flavours pre-installed in /opt as modules. 

The spack configuration builds on the built-in /opt image modules, building the applications against these. 

## Getting Started
Download and run the azure-spack.sh script (with a normal non-root user account): 

```
$ ./azure-spack.sh
Cloning into 'spack'...

At this point the following commmands should work:
[spacktest@spackhc ~]$ spack --version
0.12.1
[spacktest@spackhc ~]$ spack arch
linux-centos7-skylake
```

Now you can go ahead and run the package installer (note this can take a long time). Edit the script and hash out the packages you are not interested in, then run it: 

```
$ ./azure-pkgs.sh
```
You may also need to edit the compiler.yaml, packages.yaml & modules.yaml to customize according to your preferences. 
More details on spack <a href="https://spack.readthedocs.io">here</a>

## Known Issues:

1) Anything using Intel MPI 2019 must be built with -dirty to pickup libfabric from the modulefile until intel-mpi spack package is fixed for 2019/2020
2) HPCX package is waiting on a fix to source the built-in modulefile
3) Intel MPI 2018 & 2019 support up to gcc@8.2.0 (mainly for fortran dependent builds like hdf5)
