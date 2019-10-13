# azure-spack

Download and run the azure-spack.sh script: 

$ ./azure-spack.sh
Cloning into 'spack'...

At this point the following commmands should work:
[spacktest@spackhc ~]$ spack --version
0.12.1
[spacktest@spackhc ~]$ spack arch
linux-centos7-skylake

Now you can go ahead and run the package installer (note this can take a long... time). Hash out the packages you are not interested in: 
$ ./azure-pkgs.sh

More details on spack <a href="https://spack.readthedocs.io">here</a>
