#!/bin/bash

#
# Patchs post build du core ownCloud
#

	# Params
	output_folder=$1
	wayf_targz="mycore_wayf-1.0.tar.gz"

	# On decompresse a la racine
		printf "unTar $wayf_targz > $output_folder/ ... "
                debug=`/bin/tar zxvf $wayf_targz -C $output_folder/ 2>&1`
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

	
