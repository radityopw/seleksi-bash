#! /bin/bash
# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT



## input 
## input 1 : data penempatan
## input 2 : data peserta

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

