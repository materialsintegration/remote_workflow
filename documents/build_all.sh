#!/bin/bash

echo "すべてのマニュアルをビルドします。よろしいですか？"

directories=(./manual1st ./manual2nd ./activities_of_nims)
for dir in ${directories[@]}
do
    cd $dir
    bash build.sh 2>&1 | tee build.log
done
