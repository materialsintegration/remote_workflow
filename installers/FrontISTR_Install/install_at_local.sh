#!/bin/bash

PREFIX=~/local
export http_proxy=http://proxy-calc:8888
export https_proxy=http://proxy-calc:8888

echo "oneAPIをアンインストールしています..."
./l_BaseKit_p_2022.2.0.262_offline.sh -a --action remove -s
./l_HPCKit_p_2022.2.0.191_offline.sh -a --action remove -s
echo "~/local ディレクトリを削除しています..."
rm -rf ~/local
rm -rf ~/.intel

############################################
# cmake 
############################################
echo "installing cmake...."
#wget https://github.com/Kitware/CMake/releases/download/v3.20.2/cmake-3.20.2-linux-x86_64.tar.gz
if [ ! -e "cmake-3.20.2-linux-x86_64.tar.gz" ]; then
    echo "cmake-3.20.2-linux-x86_64.tar.gz がありません。"
    exit 1
fi
tar zxvf cmake-3.20.2-linux-x86_64.tar.gz > /dev/null 2>&1
mkdir -p $PREFIX/cmake/3.20.2
mv -f cmake-3.20.2-linux-x86_64/* $PREFIX/cmake/3.20.2/
export PATH=$PATH:$PREFIX/cmake/3.20.2/bin
echo "cmake installed."

############################################
# MPI Environment setup
############################################
#openmpi=`ls /opt | grep openmpi`
#if [ -e /usr/lib64/openmpi/bin/mpicc -a $force = "false" ]; then
#    echo "found openmpi."
#    echo "skip openmpi install"
#else
#    echo "installing openmpi...."
#    yum -y install openmpi openmpi-devel
#    #echo 'module add mpi/openmpi-x86_64' >> /etc/profile.d/sh.local
#    echo "openmpi installed."
#fi

############################################
# Intel MKL (Optional)
############################################
echo "installing oneapi Basekit..."
./l_BaseKit_p_2022.2.0.262_offline.sh -a --install-dir /home/misystem/local/intel/oneapi -s --eula accept
echo "intel oneapi Basekit installed."
echo "installing oneapi HPCkit..."
./l_HPCKit_p_2022.2.0.191_offline.sh -a --install-dir /home/misystem/local/intel/oneapi -s --eula accept
echo "intel oneapi HPCkit installed."

if [ ! -e ~/local/intel/oneapi/setvars.sh ]; then
    echo "HPCKitのインストールに失敗しました。"
    exit 1
fi
. ~/local/intel/oneapi/setvars.sh
echo "MKLモジュールのコンパイル..."
pushd ~/local/intel/oneapi/mkl/latest/interfaces/fftw3xf
make libintel64
if [ $? -ne 0 ]; then
    echo "MKLモジュールのコンパイルに失敗しました。"
    exit 1
fi
popd
############################################
# Install libxml
# you can use [yum -y install libxml-devel], instead of this script 
############################################
echo "installing libxml2-devel..."
#rm -rf ./libxml2
#git clone --depth 1 -b v2.9.10 https://gitlab.gnome.org/GNOME/libxml2.git
if [ ! -e "libxml2" ]; then
    echo "libxml2ディレクトリがありません。"
    exit 1
fi 
cd libxml2
./autogen.sh
./configure --prefix $PREFIX --enable-shared=no --with-python=no
make -j && make install
if [ $? -ne 0 ]; then
    echo "libxml2-devel(GNOME)のコンパイルに失敗しました。"
    exit 1
fi
cd ..

############################################
# Install VTK
############################################
echo "installing VTK..."
#rm -rf VTK-8.2.0 VTK-8.2.0.tar.gz
#wget https://www.vtk.org/files/release/8.2/VTK-8.2.0.tar.gz --no-check-certificate
if [ ! -e "VTK-8.2.0.tar.gz" ]; then
    echo "VTKインストールソースがありません。"
    exit 1
fi
md5sum=`md5sum VTK-8.2.0.tar.gz | awk '{print $1}'`
if [ "$md5sum" != "8af3307da0fc2ef8cafe4a312b821111" ]; then
    echo "ダウンロードファイルのmd5sum値が違いました。"
    exit 1
fi
tar zxvf VTK-8.2.0.tar.gz > /dev/null 2>&1
cd VTK-8.2.0
cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=$PREFIX -DVTK_Group_Rendering=OFF -DVTK_RENDERING_BACKEND=None -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF
if [ $? -ne 0 ]; then
    echo "VTKのコンパイルに失敗しました。"
    exit 1
fi
cmake --build build -- -j install
cd ..
echo "VTK installed."

############################################
# Install HAM (RICOS's OSS)
############################################
echo "installing HAM(RICOS's Open Source Softrware)..."
#rm -rf HAM-NIMS HAM-NIMS.tar.gz
#wget https://ritc.jp/download/HAM-NIMS.tar.gz
if [ ! -e "HAM-NIMS.tar.gz" ]; then
    echo "HAM-NIMS.tar.gz がありません。"
    exit 1
fi
tar xzvf HAM-NIMS.tar.gz > /dev/null 2>&1
cd HAM-NIMS
cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=$PREFIX
if [ $? -ne 0 ]; then
    echo "HAMのコンパイルに失敗しました。"
    exit 1
fi
cmake --build build -- -j
cp ./build/ham $PREFIX/bin/
cd ..
echo "HAM(RICOS's Open Source Sofrware) installed."

############################################
# Install FrontISTR and libs
############################################
# OpenBlas
#rm -rf OpenBLAS
echo "installing OpenBlas(for FrontISTR)..."
#git clone -b v0.3.7 --depth=1 https://github.com/xianyi/OpenBLAS.git
if [ ! -e "OpenBLAS" ]; then
    echo "OpenBALSディレクトリがありません。"
    exit 1
fi
cd OpenBLAS
make -j DYNAMIC_ARCH=1 USE_OPENMP=1 BINARY=64 NO_SHARED=1
if [ $? -ne 0 ]; then
    echo "OpenBLASのコンパイルに失敗しました。"
    exit 1
fi
make PREFIX=${PREFIX} install
cd ..
echo "OpenBlas(for FrontISTR) installed."

############################################
# METIS
echo "installing METIS(for FrontISTR)..."
#rm -rf metis-5.1.0 metis-5.1.0.tar.gz
#wget http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz
if [ ! -e "metis-5.1.0.tar.gz" ]; then
    echo "metis-5.1.0.tar.gz がありません。"
    exit 1
fi
tar xvzf metis-5.1.0.tar.gz > /dev/null 2>&1
cd metis-5.1.0
make config prefix=${PREFIX} cc=gcc openmp=1 shared=not-set
if [ $? -ne 0 ]; then
    echo "METISのコンパイルに失敗しました。"
    exit 1
fi
make install -j4
cd ..
echo "METIS(for FrontISTR) installed."

############################################
# Scalapack
echo "installing scalapack..."
#rm -rf scalapack
#git clone -b v2.1.0 --depth=1 https://github.com/Reference-ScaLAPACK/scalapack
if [ ! -e "scalapack" ]; then
    echo "scalapack ディレクトリがありません。"
    exit 1
fi
cd scalapack
cmake -Bbuild -H. -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_EXE_LINKER_FLAGS="-fopenmp" -DBLAS_LIBRARIES=$PREFIX/lib/libopenblas.a -DLAPACK_LIBRARIES=$PREFIX/lib/libopenblas.a 
if [ $? -ne 0 ]; then
    echo "scalapackのコンパイルに失敗しました。"
    exit 1
fi
cmake --build build -- -j install
cd ..
echo "scalapack installed."

############################################
# MUMPS
echo "installing MUMPS(for FrontISTR)..."
#rm -rf MUMPS_5.3.3 MUMPS_5.3.3.tar.gz
#wget http://mumps.enseeiht.fr/MUMPS_5.3.3.tar.gz
if [ ! -e "MUMPS_5.3.3.tar.gz" ]; then
    echo "MUMPS_5.3.3.tar.gzがありません。"
    exit 1
fi
tar xvzf MUMPS_5.3.3.tar.gz > /dev/null 2>&1
cd MUMPS_5.3.3
cp Make.inc/Makefile.inc.generic Makefile.inc
sed -i \
-e "s|^#LMETISDIR = .*$|LMETISDIR = ${PREFIX}|" \
-e "s|^#IMETIS    = .*$|IMETIS = -I\$(LMETISDIR)/include|" \
-e "s|^#LMETIS    = -L\$(LMETISDIR) -lmetis$|LMETIS = -L\$(LMETISDIR)/lib -lmetis|" \
-e "s|^ORDERINGSF  = -Dpord$|ORDERINGSF = -Dpord -Dmetis|" \
-e "s|^CC      = cc|CC      = mpicc|"  \
-e "s|^FC      = f90|FC      = mpif90|"  \
-e "s|^FL      = f90|FL      = mpif90|" \
-e "s|^LAPACK = -llapack|LAPACK = -L${PREFIX}/lib -lopenblas|" \
-e "s|^SCALAP  = -lscalapack -lblacs|SCALAP  = -L${PREFIX}/lib -lscalapack|" \
-e "s|^LIBBLAS = -lblas|LIBBLAS = -L${PREFIX}/lib -lopenblas|" \
-e "s|^OPTF    = -O|OPTF    = -O -fopenmp|" \
-e "s|^OPTC    = -O -I\.|OPTC    = -O -I. -fopenmp|" \
-e "s|^OPTL    = -O|OPTL    = -O -fopenmp|" Makefile.inc
make d -j; make d
if [ $? -ne 0 ]; then
    echo "MUMPSのコンパイルに失敗しました。"
    exit 1
fi
cp include/mumps*.h include/dmumps*.h ${PREFIX}/include; cp lib/*.a ${PREFIX}/lib
cd ..
echo "MUMPS(for FrontISTR) isntalled."

############################################
# Trilinos
echo "installing Trilinos(for FrontISTR)..."
#rm -rf Trilinos
#git clone -b trilinos-release-12-12-1 --depth=1 https://github.com/trilinos/Trilinos.git
if [ ! -e "Trilinos" ]; then
    echo "Trilinosディレクトリがありません。"
    exig 1
fi
cd Trilinos
cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=${PREFIX}  -DCMAKE_C_COMPILER=mpicc  -DCMAKE_CXX_COMPILER=mpicxx  -DCMAKE_Fortran_COMPILER=mpif90  -DTPL_ENABLE_LAPACK=ON  -DTPL_ENABLE_SCALAPACK=ON  -DTPL_ENABLE_METIS=ON  -DTPL_ENABLE_MUMPS=ON  -DTPL_ENABLE_MPI=ON  -DTrilinos_ENABLE_ML=ON  -DTrilinos_ENABLE_Zoltan=ON  -DTrilinos_ENABLE_OpenMP=ON  -DTrilinos_ENABLE_Amesos=OFF  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF  -DMETIS_LIBRARY_DIRS=$PREFIX/lib  -DMUMPS_LIBRARY_DIRS=$PREFIX/lib  -DBLAS_LIBRARY_DIRS=$PREFIX/lib  -DLAPACK_LIBRARY_DIRS=$PREFIX/lib  -DSCALAPACK_LIBRARY_DIRS=$PREFIX/lib  -DBLAS_LIBRARY_NAMES="openblas"  -DLAPACK_LIBRARY_NAMES="openblas" 
if [ $? -ne 0 ]; then
    echo "Trilinosのコンパイルに失敗しました。"
    exit 1
fi
cmake --build build -- -j install
cd ..
echo "Trilinos(for FrontISTR) installed."

############################################
# REVOCAP_Refiner
echo "installing REVOCAP_Refiner(for FrontISTR)..."
#rm -rf REVOCAP_Mesh
#git clone --depth=1 https://gitlab.com/FrontISTR-Commons/REVOCAP_Mesh.git
if [ ! -e "REVOCAP_Mesh" ]; then
    echo "REVOCAP_Meshディレクトリがありません。"
    exit 1
fi
cd REVOCAP_Mesh
cat ./config/MakefileConfig.LinuxCluster > MakefileConfig.in 
make -j Refiner
if [ $? -ne 0 ]; then
    echo "REVOCAP_Refinerのコンパイルに失敗しました。"
    exit 1
fi
find lib -type f -name "libRcapRefiner*" -exec cp {} ${PREFIX}/lib/ \;
find . -type f -name "rcapRefiner.h" -exec cp {} ${PREFIX}/include/ \;
cd ..
echo "REVOCAP_Refiner(for FrontISTR) installed."

############################################
# FrontISTR
echo "installing FrontISTR..."
#rm -rf FrontISTR-nims FrontISTR-nims.tar.gz
#wget https://ritc.jp/download/FrontISTR-nims.tar.gz
if [ ! -e "FrontISTR-nims.tar.gz" ]; then
    echo "FrontISTR-nims.tar.gzがありません。"
    exit 1
fi
tar xvzf FrontISTR-nims.tar.gz > /dev/null 2>&1
cd FrontISTR-nims
echo "cmake : `which cmake`"
echo "cmake : `cmake --version`"
cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=$PREFIX -DBLAS_LIBRARIES=${PREFIX}/lib/libopenblas.a -DLAPACK_LIBRARIES=${PREFIX}/lib/libopenblas.a
if [ $? -ne 0 ]; then
    echo "FrontISTRのコンパイルに失敗しました。"
    exit 1
fi
nproc=16
cmake --build build -- -j $(nproc) install
if [ $? -ne 0 ]; then
    echo "FrontISTRのインストールビルドに失敗しました。"
    exit 1
fi
cd ..
#cp sh.local /etc/profile.d
echo "FrontISTR installed."
