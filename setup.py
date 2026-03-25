from setuptools import setup
from setuptools.command.build import build
from glob import glob
import subprocess
import shutil
import os
import re

class CustomBuild(build):
    # custom build commands
    def run(self):
        # run cmake
        builddir_name = "build_pip"
        try:
            subprocess.run(
                ["cmake","-B", builddir_name],
                check=True,
                capture_output=True)
        except subprocess.CalledProcessError as e:
            print( e.stdout)
            print(e.stderr)
            raise SystemExit(1)
        try:
            subprocess.run(
                ["cmake", "--build", builddir_name],
                check=True,
                capture_output=True)
        except subprocess.CalledProcessError as e:
            print(e.stdout)
            print(e.stderr)
            raise SystemExit(2)

        ## copy libira.so into site-packages/ira_mod/lib ::
        # find extension (.so/.dylib/etc.)
        libfname=glob("lib/libartn.*")[0]
        f,ext=os.path.splitext(libfname)
        # libira.so path
        so_src = os.path.abspath(os.path.join('lib', 'libartn'+ext))
        # self.build_lib is location for python/site-packages;
        # append 'pypARTn/lib' to it.
        build_dir_lib = os.path.join(self.build_lib, "pypARTn/lib")
        if not os.path.exists(build_dir_lib):
            os.makedirs(build_dir_lib)
        # copy libartn to builddir_path
        shutil.copy2(so_src, build_dir_lib)

        super().run()

## get version number
with open(os.path.abspath("src/artn_version.h"), "r" ) as f:
    for line in f:
        if( "ARTN_VERSION" in line):
            vstr=line.strip()
vstr=vstr.split()[2].strip('"')


setup(
    name="pypARTn",
    version=vstr,
    description="Open-ended exploration of saddle points on PES",
    author="MAMMASMIAS Consortium",
    url="https://gitlab.com/mammasmias/artn-plugin",
    license_expression="GPL-3.0-or-later OR Apache-2.0",
    packages=['pypARTn'],
    package_dir={'pypARTn': 'interface'},
    include_package_data=True,
    cmdclass={'build': CustomBuild},
    ext_modules=[],
    install_requires=[
        "numpy>=2.2.6"
    ]
)

