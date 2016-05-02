#!/bin/bash

#
# Patchs post build du core ownCloud, about settings/users bug (broken select box in certain cases)
#

	# Params
	output_folder=$1

	# Copie la version avec correctif du fichier userlist.php
		printf "Override ${output_folder}/settings/ajax/userlist.php  with  ./core_patches/userlist.php "
                debug=$(cp ./core_patches/userlist.php ${output_folder}/settings/ajax/userlist.php 2>&1)
                if [ $? -ge "1" ]
                then
                	# Cmd fail
                        echo "FAIL"
                        echo $debug
                        exit
                else
                        # Cmd OK
                	echo "OK"
		fi
