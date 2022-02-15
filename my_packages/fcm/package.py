# Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Fcm(Package):
    """FCM: Flexible Configuration Management System a modern Fortran build system, and wrappers to Subversion for scientific software development."""

    homepage = "https://github.com/metomi/fcm"
    url      = "https://github.com/metomi/fcm/archive/refs/tags/2021.05.0.tar.gz"

    version('2021.05.0', sha256='b4178b488470aa391f29b46d19bd6395ace42ea06cb9678cabbd4604b46f56cd')
    version('2019.09.0', sha256='0c291c652d6d2827a789cc326d9f2e3b2daa2a10aae7faa72d2fad3fd8a650c2')
    version('2019.05.0', sha256='ad080659412ecd6ad6251567c9c332b58fe28c7770b48c14ede6d32191926494')
    version('2017.10.0', sha256='cb8051f2a23239a2f9cc65cc2793f02bfcee7282e923f3f34be03571e2ff167f')
    version('2017.09.0', sha256='03c46884a27adc9d9ca6a1ad8079e7143b53bee25ee7b35c241a731b602aedfa')
    version('2017.02.0', sha256='5de31bc944f2e7598920bcb8d934537e82d45cb6c57c7a6224713821fa39111f')
    version('2016.12.0', sha256='013a9af8f4d644a334286099b2cd606103aae3a88626fc3a0027d915a0bd5e1a')
    version('2016.10.0', sha256='bdd48f50d44b6f99995cafab6611fdf967f2ba5b9384f03a24e10135de6b60e4')
    version('2016.09.0', sha256='ec5d3169db0265478e9acb42fa3e6eaa1b0ec55e9ad1d0b75f7144cd3662a01b')
    version('2016.05.1', sha256='eabb1743976b57ff07a87bb37176465bdad15e0cea84e59894f56ebc6891f8c9')

    #-- requirements here: http://metomi.github.io/fcm/doc/installation/
    depends_on('perl')
    depends_on('subversion')
    depends_on('rsync')

    # Perl modules:
    depends_on('perl-config-inifiles') # Config::IniFiles
    depends_on('perl-dbd-sqlite')      # DBD::SQLite
    #depends_on('perl-alien-svn')       # SVN::Client --> hitting an issue with shebang length here
    depends_on('perl-xml-parser')      # XML::Parser
    depends_on('perl-digest-md5')      # Digest::MD5
    depends_on('perl-time-piece')      # Time::Piece
   
    # Perl-Tk needs os package libX11-devel headers (CentOS/RedHat) or libx11-dev (Ubuntu/Debian)
    depends_on('perl-tk')

    def install(self, spec, prefix):
       copy_tree(".",prefix, symlinks=True, ignore=None, _permissions=False)

    #   sanity_check_is_file = [join_path('bin', 'fcm')]
