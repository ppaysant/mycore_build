#!/bin/bash

# Params
output_folder=$1

# Supprime le contenu du dossier core/skeleton/
	printf "removeSkeleton > $output_folder/core/skeleton/* ... "
        debug=`/bin/rm -rf $output_folder/core/skeleton/* 2>&1`
        if [[ $? -ge "1" ]]
        then
        	# Cmd fail
                echo "FAIL"
                echo $debug
                exit
        else
                # Cmd OK
        	echo "OK"
	fi

