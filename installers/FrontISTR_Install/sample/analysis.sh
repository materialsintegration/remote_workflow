#!/bin/bash

INP_FILE=$1
CALCCOND_FILE=$2
MATPARA_FILE=$3

ham --input $INP_FILE --input-type ABAQUS --input-calccond $CALCCOND_FILE --input-matpara $MATPARA_FILE --output mesh.msh mesh.cnt --output-type FrontISTR
fistr1
