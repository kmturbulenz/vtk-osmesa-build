#############################
VTK with OSMesa Python wheels
#############################

The Visualization Toolkit (VTK) [1]_ by Kitware is a great package for making
complex postprocessing operations and 3D visualizations.

Several Python projects depend on VTK. One drawback with the official Python
wheels published on PyPi [2]_ is that they require GPU hardware and an X server
to work. Another drawback is that SMP (threading) is not enabled.

For high performance post-processing and visualization on remote systems without
GPU's it is possible to build VTK with OSMesa (Offscreen Software Mesa) [3]_
support, however, pre-built Python wheels with this is not available.

This repository contain scripts and pre-built VTK wheels with OSMesa and SMP
support for these cases.

*************
Build process
*************
The build process is inside a container. The container image form [4]_
is based on Centos 7 and contains updated and optimized builds of LLVM,
OSMesa (built with ``-march=x86-64-v2``) and TBB [5]_ (for SMP). With
this, the VTK library are built.

The produced Python wheel is manually manipulated and the relevant shared
libraries for OSMesa and TBB are inserted. This is to produce a self-contained
wheel that do not require special system packages installed.

The build is automated with Github Actions, and the resulting build logs and
wheel(s) are uploaded as build artifacts. When a tag is added to the repository
a release is automatically created and uploaded.

***********
Local build
***********
If you want to build VTK locally on your own computer, using the same
container image and build script, you can checkout this repository
and run the command::

    docker run --user="$(id -u):$(id -g)" --read-only --rm --volume="$PWD:/input" --workdir="/input" ghcr.io/kmturbulenz/llvm-osmesa-image:master ./build.sh

****************
Missing features
****************
* There are little or no debugging support due to the compile-time optimizations
* Only a Python 3.8 wheel is built

********
Warnings
********
Software rendering is slow. Very slow. There are no hardware rendering support
in this build.

**********
References
**********
.. [1] https://vtk.org/
.. [2] https://pypi.org/project/vtk/
.. [3] https://docs.mesa3d.org/osmesa.html
.. [4] https://github.com/kmturbulenz/llvm-osmesa-image
.. [5] https://github.com/oneapi-src/onetbb
