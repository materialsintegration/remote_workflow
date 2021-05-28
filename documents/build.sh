#!/bin/sh
# MIシステム利用手引書、ビルドスクリプト for Jenkins

export PATH=/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/gcc-4.8.5/lib
directories=(./manual1st ./manual2nd ./activities_of_nims)
pdffilenames=(外部計算資源の利用１期 外部計算資源の利用２期 NIMSの取り組みについて)
count=0
logfile="`pwd`/build.log"
if [ -e $logfile ]; then
    rm $logfile
fi
touch $logfile
for dir in ${directories[@]}
do
    cd $dir
    make clean
    # make reStracturedText to PDF via tex documents
    echo "-------------------- build latex files ----------" >> $logfile
    echo "make latex" >> $logfile 2>&1
    make latex >> $logfile 2>&1
    echo "-------------------- 1st compile dvi file -----------" >> $logfile
    pushd build/latex
    echo "platex -f --interaction=nonstopmode sphinx.tex" >> $logfile 2>&1
    platex -f --interaction=nonstopmode sphinx.tex >> $logfile 2>&1
    echo "-------------------- 2nd compile dvi file -----------" >> $logfile
    echo "platex -f --interaction=nonstopmode sphinx.tex" >> $logfile 2>&1
    platex -f --interaction=nonstopmode sphinx.tex >> $logfile 2>&1
    echo "-------------------- convert pdf file -----------" >> $logfile
    echo "dvipdfmx sphinx.dvi" >> $logfile 2>&1
    dvipdfmx sphinx.dvi >> $logfile 2>&1
    if [ -e "sphinx.pdf" ]; then
        # とりあえず成果物確認用ページへコピーする。
        # 本来はちゃんとした公開ページへコピーすること。
        echo "copy sphinx.pdf to ${pdffilenames[$count]}.pdf" >> $logfile
        #cp sphinx.pdf /var/lib/mi-docroot/static/misystem-user-manual/${pdffilenames[$count]}.pdf
        mv sphinx.pdf ${pdffilenames[$count]}.pdf
        let count++
    fi
    popd
    echo "-------------------- generate web pages ---------" >> $logfile
    echo "make html" >> $logfile 2>&1
    make html >> $logfile 2>&1
    #cd build
    #if [ -e /var/lib/mi-docroot/static/misystem-user-manual/html ]; then >> $logfile
    #    rm -rf /var/lib/mi-docroot/static/misystem-user-manual/html >> $logfile
    #fi >> $logfile
    #cp -rp html /var/lib/mi-docroot/static/misystem-user-manual
    #cd ../
    if [ -e "source/images" ]; then
        cp source/images/*.png build/html/_images
    fi
    cd ../
done

# copy to public space for documents

