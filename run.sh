#!/bin/bash

# pass all arguments to the main script
database=$(mktemp -p /tmp seleksi.XXXXXX)

./main.sh $database "$@"
EXITCODE=$?

if [[ $EXITCODE -eq 1 ]]
then
	jml_file=$(( $(ls $database 2> /dev/null | wc -l) + 0  ))
	if [[ $jml_file -gt 0 ]]
	then
		rm $database
	fi

fi
