#!/bin/bash

#
# Patchs post build du core ownCloud
#

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
	# Récupère le fichier userlist.php et le met dans settings/ajax/
		printf "userlist.php > $output_folder/settings/ajax/ ... "
                debug=`wget -q https://raw.githubusercontent.com/CNRS-DSI-Dev/mycore_build/1a1fd84b32b1a0e5b93fc823ad9e38081c13aae3/core_patches/userlist.php -O $output_folder/settings/ajax/userlist.php 2>&1`
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

