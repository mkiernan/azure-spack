# azure-spack

Setup scripts to get <a href="https://spack.readthedocs.io">Spack</a> running on the Azure HC44rs/HB60rs HPC platforms. The scripts are designed to be run on the Azure OpenLogic:CentOS-HPC:7.6:latest operating system image, which comes with all SR-IOV ready MPI flavours pre-installed in /opt as modules. 

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

More details on spack <a href="https://spack.readthedocs.io">here</a>
