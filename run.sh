#! /bin/bash
# exit when any command fails
set -e

# keep track of the last executed command
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
#trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT


## functions


help(){

	# Display Help
	echo "Syntax: run.sh dpn dps [-h]"
	echo 
	echo "options : "
	echo "dpn	lokasi data penempatan csv"
	echo "dps	lokasi data peserta csv"
	echo "h 	print help"	

}


## setting global variables

data_penempatan=""
data_peserta=""
number_params=0

## input 
## input 1 : data penempatan
## input 2 : data peserta

while getopts ":h" option; do
	case $option in
		h) # display Help
			help
			exit;;
		\?) # invalid options
			help
			exit;;
	esac
done

if [ $# -eq 2 ] 
then
	number_params=$#
	data_penempatan=$1
	data_peserta=$2

else
	help
	exit 1
fi

## preparasi data
## 1. buat folder temporary
## 2. copy database.db ke point 1 -> database_aktif.db

## import data ke dalam database
## 1. import data penempatan ke database_aktif.db
## 2. import data peserta ke database_aktif.db
## jika terdapat error maka system halted

## proses seleksi 
## 1.deteksi ada berapa pilihan maksimal pada data peserta 
## 2.buat fungsi yang melakukan seleksi pilihan 1
## 3.buat fungsi yang melakukan seleksi pilihan 2 dst ( looping sampai tidak ada lagi yang eligible )


## output list nomor peserta dan kode penempatan 

