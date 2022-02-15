# Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class PerlConfigInifiles(PerlPackage):
    """Config::IniFiles - A module for reading .ini-style configuration files."""

    homepage = "https://metacpan.org/pod/Config::IniFiles"
    url      = "https://cpan.metacpan.org/authors/id/S/SH/SHLOMIF/Config-IniFiles-3.000003.tar.gz"

    version('3.000003', sha256='3c457b65d98e5ff40bdb9cf814b0d5983eb0c53fb8696bda3ba035ad2acd6802')
