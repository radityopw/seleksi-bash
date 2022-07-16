#! /bin/bash
# exit when any command fails
set -e

#force working directory on this file
cd "$(dirname "$0")"

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

cleanup(){
	rm $database
	#echo $database
}

hitung_min_nilai(){
	sqlite3 $database "DELETE FROM _min_nilai;"

	sqlite3 $database "INSERT INTO _min_nilai(kode_penempatan,min_nilai)
			   SELECT kode_penempatan,nilai
			   FROM (
			   	SELECT a.kode_penempatan,min(a.nilai) as nilai,b.daya_tampung,count(a.kode_peserta) as jml_terima
			   	FROM _peserta_diterima_final a
			   	JOIN penempatan b ON a.kode_penempatan = b.kode_penempatan
			   	GROUP BY a.kode_penempatan,b.daya_tampung
			   ) as table_a
			   WHERE jml_terima = daya_tampung;"

	sqlite3 $database "INSERT INTO _min_nilai(kode_penempatan,min_nilai)
			   SELECT kode_penempatan,-9999
			   FROM penempatan
			   WHERE kode_penempatan NOT IN (
			   	SELECT DISTINCT kode_penempatan
				FROM _min_nilai
			   );"
}

hitung_sisa_peminat(){
	sisa_peminat=$(( $( sqlite3 $database "SELECT count(*)
				   	       FROM peserta a
				   	       JOIN _min_nilai b ON a.kode_penempatan = b.kode_penempatan
				   	       WHERE a.KODE_PESERTA NOT IN (
							SELECT kode_peserta
					   		FROM _peserta_diterima_final
					       ) AND a.nilai > b.min_nilai;" ) + 0 ))
}


## setting global variables

declare -i number_params
declare -i max_pil
declare -i sisa_peminat


data_penempatan=""
data_peserta=""
number_params=0
database=""
max_pil=0
sisa_peminat=0

## input 
## input 1 : data penempatan
## input 2 : data peserta

while getopts ":h" option; do
	case $option in
		h) # display Help
			help
			exit
			;;
		\?) # invalid options
			help
			exit
			;;
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
## 1. buat temporary file
## 2. copy database.db ke point 1 -> database_aktif.db
database=$(mktemp -p /tmp seleksi.XXXXXX)
cp database.db $database


## import data ke dalam database
## 1. import data penempatan ke database_aktif.db
## 2. import data peserta ke database_aktif.db
## jika terdapat error maka system halted

sqlite3 $database "DELETE FROM peserta_diterima; DELETE FROM peserta; DELETE FROM penempatan;"

sqlite3 $database ".import --csv --skip 1 "$data_penempatan" penempatan"
sqlite3 $database ".import --csv --skip 1 "$data_peserta" peserta"

## proses seleksi 
## 1.deteksi ada berapa pilihan maksimal pada data peserta 
## 2.buat fungsi yang melakukan seleksi pilihan 1
## 3.buat fungsi yang melakukan seleksi pilihan 2 dst ( looping sampai tidak ada lagi yang eligible )

sqlite3 $database "DELETE FROM _peserta_diterima_matic; DELETE FROM _peserta_diterima_final;"
max_pil=$(( $(sqlite3 $database "SELECT max(pil_ke) FROM peserta") + 0 ))


hitung_min_nilai
hitung_sisa_peminat

while [[ $sisa_peminat -gt 0 ]]
do

	sqlite3 $database "DELETE FROM _peserta_diterima_matic;"

	sqlite3 $database "INSERT INTO _peserta_diterima_matic(kode_peserta,kode_penempatan,pil_ke,nilai)
			   SELECT kode_peserta,kode_penempatan,pil_ke,nilai
			   FROM (
				   SELECT ax.KODE_PESERTA,ax.KODE_PENEMPATAN,ax.PIL_KE,ax.NILAI
					 ,ROW_NUMBER() OVER(PARTITION BY ax.KODE_PENEMPATAN ORDER BY ax.NILAI DESC) as rn
					 ,b.daya_tampung
				   FROM (
					   SELECT KODE_PESERTA,KODE_PENEMPATAN,PIL_KE,NILAI
					   FROM _peserta_diterima_final
					   UNION
					   SELECT KODE_PESERTA,KODE_PENEMPATAN,PIL_KE,NILAI
					   FROM (
						   SELECT a.KODE_PESERTA,a.KODE_PENEMPATAN,a.PIL_KE,a.NILAI
							 ,ROW_NUMBER() OVER(PARTITION BY a.kode_peserta ORDER BY a.pil_ke ASC) as rn
						   FROM peserta a
						   JOIN _min_nilai b ON a.kode_penempatan = b.kode_penempatan
						   WHERE a.KODE_PESERTA NOT IN (
							SELECT kode_peserta
							FROM _peserta_diterima_final
						   ) AND a.nilai > b.min_nilai
					   ) a
					   WHERE rn = 1
				   ) ax
				   JOIN penempatan b ON ax.KODE_PENEMPATAN = b.KODE_PENEMPATAN 
			    ) axx 
			    WHERE rn <= daya_tampung;"
	
	sqlite3 $database "DELETE FROM _peserta_diterima_final;"
	sqlite3 $database "INSERT INTO _peserta_diterima_final(kode_peserta,kode_penempatan,pil_ke,nilai)
			   SELECT kode_peserta,kode_penempatan,pil_ke,nilai
			   FROM _peserta_diterima_matic;"

	hitung_min_nilai
	hitung_sisa_peminat
done

sqlite3 $database "DELETE FROM peserta_diterima;"
sqlite3 $database "INSERT INTO peserta_diterima(kode_peserta,kode_penempatan,pil_ke,nilai)
		   SELECT kode_peserta,kode_penempatan,pil_ke,nilai
		   FROM _peserta_diterima_final;"

## output list nomor peserta dan kode penempatan 

sqlite3 $database "SELECT kode_peserta,kode_penempatan,pil_ke,nilai
	           FROM peserta_diterima;" 

cleanup
exit 0
