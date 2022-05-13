#!/bin/bash

INP_FILE=$1
CALCCOND_FILE=$2
MATPARA_FILE=$3
NPROCS=$4

ham --input $INP_FILE --input-type ABAQUS --input-calccond $CALCCOND_FILE --input-matpara $MATPARA_FILE --output mesh.msh mesh.cnt --output-type FrontISTR

cat > hecmw_part_ctrl.dat <<EOL
!PARTITION, TYPE=NODE-BASED,METHOD=PMETIS,DOMAIN=$NPROCS, UCD=part.inp
EOL

cat > hecmw_ctrl.dat <<EOL
# for partitioner
!MESH, NAME=part_in,TYPE=HECMW-ENTIRE
 mesh.msh
!MESH, NAME=part_out,TYPE=HECMW-DIST
 mesh.msh
# for solver
!MESH, NAME=fstrMSH, TYPE=HECMW-DIST
 mesh.msh
!CONTROL, NAME=fstrCNT
 mesh.cnt
!RESULT, NAME=fstrRES, IO=OUT
 mesh.res
!RESULT, NAME=vis_out, IO=OUT
 mesh_vis
# for restart
!RESTART,NAME=restart_out,IO=INOUT
 mesh.restart
!SUBDIR, ON
EOL


hecmw_part1
mpirun -n $NPROCS fistr1 -t 1