#!/bin/bash

echo "Compiling VTK"

source scl_source enable rh-git227
source scl_source enable rh-python38
source /opt/python38/bin/activate

set -o verbose
set -o errexit

PWD0=$(pwd)

# VTK compilation
VTK_BRANCH="master"
VTK_COMMIT="38cd588d"
VTK_URL="https://gitlab.kitware.com/vtk/vtk.git"

git clone -b $VTK_BRANCH --single-branch $VTK_URL
cd vtk
git checkout $VTK_COMMIT

VTK_MAJOR_VERSION=$(grep -oP '(?<=set\(VTK_MAJOR_VERSION )([0-9]+)' CMake/vtkVersion.cmake)
VTK_MINOR_VERSION=$(grep -oP '(?<=set\(VTK_MINOR_VERSION )([0-9]+)' CMake/vtkVersion.cmake)
VTK_BUILD_VERSION=$(grep -oP '(?<=set\(VTK_BUILD_VERSION )([0-9]+)' CMake/vtkVersion.cmake)
VTK_VER="${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}.${VTK_BUILD_VERSION}"


mkdir build && cd build
export LDFLAGS="-fuse-ld=lld"
cmake -GNinja \
    -DVTK_BUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DVTK_WHEEL_BUILD=ON \
    -DVTK_WRAP_PYTHON=ON \
    -DVTK_PYTHON_VERSION=3 \
    -DVTK_OPENGL_HAS_OSMESA=True \
    -DVTK_USE_X=False \
    -DVTK_DEFAULT_RENDER_WINDOW_OFFSCREEN=ON \
    -DVTK_SMP_IMPLEMENTATION_TYPE=TBB \
    -DVTK_SMP_ENABLE_SEQUENTIAL=ON \
    -DVTK_SMP_ENABLE_STDTHREAD=ON \
    -DVTK_SMP_ENABLE_TBB=ON \
    -DVTK_SMP_ENABLE_OPENMP=ON \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
     ../ 2>&1 | tee $PWD0/cmake.log
ninja 2>&1 | tee $PWD0/ninja.log
pip wheel --wheel-dir dist . 2>&1 | tee $PWD0/pip_wheel.log

# Manually 'patch' produced wheel, adding OSMesa and TBB shared libraries
# Maybe strictly not neccesary to pathcelf libOSMesa.so and libomp.so since
# they do not load any other libraries from the same folder - but it
# does not hurt (I think...)
VTK_PYVER="${VTK_VER}.dev0"
mkdir patch-vtkwheel && cd patch-vtkwheel
wheel unpack ../dist/vtk-${VTK_PYVER}-cp38-cp38-linux_x86_64.whl
cp $OSMESA_ROOT/lib64/libOSMesa.so.8.0.0 vtk-${VTK_PYVER}/vtkmodules/libOSMesa.so.8
cp /usr/local/lib/libomp.so vtk-${VTK_PYVER}/vtkmodules/
patchelf --set-rpath "\$ORIGIN" vtk-${VTK_PYVER}/vtkmodules/libOSMesa.so.8
patchelf --set-rpath "\$ORIGIN" vtk-${VTK_PYVER}/vtkmodules/libomp.so
cp /opt/mesa/mesa-${MESA_VER}/docs/license.rst vtk-${VTK_PYVER}/vtk-${VTK_PYVER}.dist-info/LICENSE-OSMesa.rst
cp /opt/llvm-build/llvm-project-${LLVM_VER}.src/openmp/LICENSE.TXT vtk-${VTK_PYVER}/vtk-${VTK_PYVER}.dist-info/LICENSE-libomp.TXT
cp $TBB_ROOT/lib/intel64/gcc4.8/libtbb* vtk-${VTK_PYVER}/vtkmodules/
cp $TBB_ROOT/LICENSE.txt vtk-${VTK_PYVER}/vtk-${VTK_PYVER}.dist-info/LICENSE-TBB.txt
wheel pack --dest-dir $PWD0 vtk-${VTK_PYVER}
cd -
rm -rf patch-vtkwheel

# Produce an auditwheel show log - but do not try to repair...
cd $PWD0
auditwheel show vtk-*.whl 2>&1 | tee $PWD0/auditwheel.log
