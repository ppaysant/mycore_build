#!/bin/bash

#
# Patchs post build du core ownCloud
#

        # Params
        output_folder=$1
	mapconf_name="cnrs-ppconfig.json"
	mapconf_content="{
	\"separator\": \"@\", 
	\"mapping\": {
		\"ou\":\"grp\", 
		\"o\" :\"org\",
		\"dr\": \"dr\" 
	}
}"

        # Ajout du fichier de mapping des groupes dans le dossier custom/ de l'app servervars2
                printf "addMapConf > $output_folder/apps/user_servervars2/custom/$mapconf_name ... "
                debug=`/bin/echo $mapconf_content > $output_folder/apps/user_servervars2/custom/$mapconf_name 2>&1`
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
