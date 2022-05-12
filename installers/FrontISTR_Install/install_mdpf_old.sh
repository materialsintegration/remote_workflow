#!/bin/bash

PREFIX=~/local
mkdir ~/local/bin
mkdir ~/local/include
mkdir ~/local/share
mkdir ~/local/lib
mkdir ~/local/lib64
export https_proxy=http://wwwout.nims.go.jp:8888
#cd /tmp

############################################
# cmake 
############################################
#wget https://github.com/Kitware/CMake/releases/download/v3.20.2/cmake-3.20.2-linux-x86_64.tar.gz
tar zxvf cmake-3.20.2-linux-x86_64.tar.gz
mkdir -p ~/local/cmake/3.20.2
mv -f cmake-3.20.2-linux-x86_64/* ~/local/cmake/3.20.2/

export PATH=$PATH:~/local/cmake/3.20.2/bin

############################################
# Intel MKL (Optional)
############################################

############################################
# Install libxml
# you can use [yum -y install libxml-devel], instead of this script 
############################################
#git clone --depth 1 -b v2.9.10 https://gitlab.gnome.org/GNOME/libxml2.git
#cd libxml2
#./autogen.sh
#./configure --prefix $PREFIX --enable-shared=no --with-python=no
#make -j && make install
#cd ..

############################################
# Install VTK
############################################
#wget https://www.vtk.org/files/release/8.2/VTK-8.2.0.tar.gz
tar zxvf VTK-8.2.0.tar.gz
cd VTK-8.2.0
cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=$PREFIX -DVTK_Group_Rendering=OFF -DVTK_RENDERING_BACKEND=None -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF
cmake --build build -- -j install
cd ..

############################################
# Install HAM (RICOS's OSS)
############################################
#wget https://ritc.jp/download/HAM-NIMS.tar.gz
tar xzvf HAM-NIMS.tar.gz
cd HAM-NIMS
cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=$PREFIX
cmake --build build -- -j
cp ./build/ham $PREFIX/bin/
cd ..


############################################
# Install FrontISTR and libs
############################################
# OpenBlas
#git clone -b v0.3.7 --depth=1 https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS
make -j DYNAMIC_ARCH=1 USE_OPENMP=1 BINARY=64 NO_SHARED=1
make PREFIX=${PREFIX} install
cd ..
# METIS
#wget http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz
tar xvzf metis-5.1.0.tar.gz
cd metis-5.1.0
make config prefix=${PREFIX} cc=gcc openmp=1 shared=not-set
make install -j4
cd ..
# Scalapack
#git clone -b v2.1.0 --depth=1 https://github.com/Reference-ScaLAPACK/scalapack
#cd scalapack
#cmake -Bbuild -H. -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_EXE_LINKER_FLAGS="-fopenmp" -DBLAS_LIBRARIES=$PREFIX/lib/libopenblas.a -DLAPACK_LIBRARIES=$PREFIX/lib/libopenblas.a 
#cmake --build build -- -j install
#cd ..
# MUMPS
#wget http://mumps.enseeiht.fr/MUMPS_5.3.3.tar.gz
#tar xvzf MUMPS_5.3.3.tar.gz
#cd MUMPS_5.3.3
#cp Make.inc/Makefile.inc.generic Makefile.inc
#sed -i \
#  -e "s|^#LMETISDIR = .*$|LMETISDIR = ${PREFIX}|" \
#  -e "s|^#IMETIS    = .*$|IMETIS = -I\$(LMETISDIR)/include|" \
#  -e "s|^#LMETIS    = -L\$(LMETISDIR) -lmetis$|LMETIS = -L\$(LMETISDIR)/lib -lmetis|" \
#  -e "s|^ORDERINGSF  = -Dpord$|ORDERINGSF = -Dpord -Dmetis|" \
#  -e "s|^CC      = cc|CC      = mpicc|"  \
#  -e "s|^FC      = f90|FC      = mpif90|"  \
#  -e "s|^FL      = f90|FL      = mpif90|" \
#  -e "s|^LAPACK = -llapack|LAPACK = -L${PREFIX}/lib -lopenblas|" \
#  -e "s|^SCALAP  = -lscalapack -lblacs|SCALAP  = -L${PREFIX}/lib -lscalapack|" \
#  -e "s|^LIBBLAS = -lblas|LIBBLAS = -L${PREFIX}/lib -lopenblas|" \
#  -e "s|^OPTF    = -O|OPTF    = -O -fopenmp|" \
#  -e "s|^OPTC    = -O -I\.|OPTC    = -O -I. -fopenmp|" \
#  -e "s|^OPTL    = -O|OPTL    = -O -fopenmp|" Makefile.inc
#make d -j; make d
#cp include/mumps*.h include/dmumps*.h ${PREFIX}/include; cp lib/*.a ${PREFIX}/lib
#cd ..
# Trilinos
#git clone -b trilinos-release-12-12-1 --depth=1 https://github.com/trilinos/Trilinos.git
cd Trilinos
cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=${PREFIX}  -DCMAKE_C_COMPILER=mpicc  -DCMAKE_CXX_COMPILER=mpicxx  -DCMAKE_Fortran_COMPILER=mpif90  -DTPL_ENABLE_LAPACK=ON  -DTPL_ENABLE_SCALAPACK=ON  -DTPL_ENABLE_METIS=ON  -DTPL_ENABLE_MUMPS=ON  -DTPL_ENABLE_MPI=ON  -DTrilinos_ENABLE_ML=ON  -DTrilinos_ENABLE_Zoltan=ON  -DTrilinos_ENABLE_OpenMP=ON  -DTrilinos_ENABLE_Amesos=OFF  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF  -DMETIS_LIBRARY_DIRS=$PREFIX/lib  -DMUMPS_LIBRARY_DIRS=$PREFIX/lib  -DBLAS_LIBRARY_DIRS=$PREFIX/lib  -DLAPACK_LIBRARY_DIRS=$PREFIX/lib  -DSCALAPACK_LIBRARY_DIRS=$PREFIX/lib  -DBLAS_LIBRARY_NAMES="openblas"  -DLAPACK_LIBRARY_NAMES="openblas" 
cmake --build build -- -j install
cd ..
# REVOCAP_Refiner
#git clone --depth=1 https://gitlab.com/FrontISTR-Commons/REVOCAP_Mesh.git
cd REVOCAP_Mesh
cat ./config/MakefileConfig.LinuxCluster > MakefileConfig.in 
make -j Refiner
find lib -type f -name "libRcapRefiner*" -exec cp {} ${PREFIX}/lib/ \;
find . -type f -name "rcapRefiner.h" -exec cp {} ${PREFIX}/include/ \;
cd ..

# FrontISTR
#wget https://ritc.jp/download/FrontISTR-nims.tar.gz
tar xvzf FrontISTR-nims.tar.gz
cd FrontISTR-nims
cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=$PREFIX -DBLAS_LIBRARIES=${PREFIX}/lib/libopenblas.a -DLAPACK_LIBRARIES=${PREFIX}/lib/libopenblas.a
cmake --build build -- -j $(nproc) install
cd ..

