#!/bin/bash

# pass all arguments to the main script
./main.sh "$@"
EXITCODE=$?

if [[ $EXITCODE -eq 1 ]]
then
	jml_file=$(( $(ls /tmp/seleksi.* 2> /dev/null | wc -l) + 0  ))
	if [[ $jml_file -gt 0 ]]
	then
		rm /tmp/seleksi.*
	fi

fi
