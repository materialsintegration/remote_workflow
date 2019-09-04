#!/bin/sh
# MIシステム利用手引書、ビルドスクリプト for Jenkins

export PATH=/usr/local/bin:$PATH
directories=(./)
pdffilenames=(外部計算資源の利用)
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
    echo "uplatex -f --interaction=nonstopmode 外部計算資源の利用.tex" >> $logfile 2>&1
    uplatex -f --interaction=nonstopmode 外部計算資源の利用.tex >> $logfile 2>&1
    echo "-------------------- 2nd compile dvi file -----------" >> $logfile
    echo "uplatex -f --interaction=nonstopmode 外部計算資源の利用.tex" >> $logfile 2>&1
    uplatex -f --interaction=nonstopmode 外部計算資源の利用.tex >> $logfile 2>&1
    echo "-------------------- convert pdf file -----------" >> $logfile
    echo "dvipdfmx 外部計算資源の利用.dvi" >> $logfile 2>&1
    dvipdfmx 外部計算資源の利用.dvi >> $logfile 2>&1
    if [ -e "外部計算資源の利用.pdf" ]; then
        # とりあえず成果物確認用ページへコピーする。
        # 本来はちゃんとした公開ページへコピーすること。
        echo "copy 外部計算資源の利用.pdf to ${pdffilenames[$count]}.pdf" >> $logfile
        cp 外部計算資源の利用.pdf /var/lib/mi-docroot/static/misystem-user-manual/${pdffilenames[$count]}.pdf
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
    cd ../
done

# copy to public space for documents

