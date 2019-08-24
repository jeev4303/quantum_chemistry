#!/bin/bash


read -p "enter The path to dowload :" path

read -p "enter The file name to download :"  file_name

##echo "path and  file to download is - $path/$file_name"

scp -r nambiyrk@ilogin.ibex.kaust.edu.sa:$path/$file_name .
