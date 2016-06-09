#!/bin/bash

apacheUID="www-data"
apacheGID="www-data"

#
# Parametres
#
    # Liste des items a ajouter
    conf_file=$1
    conf_delimiter=";"
    # Dossier de sortie ainsi que le nom du tar.gz
    output_folder=$2
    current_folder=`/bin/pwd`
    # Version PROD ou TEST
    environment=$3
    # App à tester
    appToTest=$4

#
# Checks
#
    # Display help
    #
    function displayHelp {
        echo "Usage : ./mycore_build.sh <conf_file> <output_folder> <[{PRODUCTION|DEV|TEST [app]}]>"
    }

    # Verif dossier destination
        if [[ $output_folder == "" || $conf_file == "" ]]
        then
                echo "Vous devez spécifier un fichier de configuration et un repertoire de sortie"
                displayHelp
                exit
        fi

    # On empeche d'ecraser un build precedent
        if [[ -d $output_folder ]]
        then
            echo "Le dossier $output_folder existe deja !"
            displayHelp
            exit
        fi

        # Verif dossier destination
        if [[ $environment != "" ]]
        then
            if [[ $environment == "PRODUCTION" || $environment == "TEST" ]]
             then
                echo "[INFO] Paramètres OK"
            else
                echo "Vous devez spécifier un mode cible, PRODUCTION ou TEST (sans fichiers git/svn),  ou DEV (avec git/svn)"
                displayHelp
                exit
            fi
        else
            if [[ $environment == "" ]]
            then
                echo "[INFO] Paramètre environment non renseigné, par défaut valorisé à PRODUCTION"
                environment="PRODUCTION"
            fi
        fi

#
# Fonctions
#

    # GetSource - DL sources d'un item
    # Recup des sources de l'item suivant la location et place l'item dans l'arborescence cible
    function getSource {
        # URL ou chemin vers un item
        getSource_location=$1
        # Chemin cible calculé avant en fonction du type
        getSource_target=$2
        # GitHub tag
        getSource_tag=$3
        # App subdir
        getSource_subdir=$4

        # Location : Github
        # Alors clone github + clean meatadata .git*
        if [[ $getSource_location =~ https://github.com/.* ]]
        then
            # clone(=checkout) d'une branche particuliere(=tag)

            gitDepth=''
            if [ ${environment} != DEV ]
            then
                gitDepth="--depth=1"
            fi

            printf "getSource github > $getSource_target ... "
            debug=`/usr/bin/git clone --branch $getSource_tag ${gitDepth} $getSource_location $getSource_target 2>&1`
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

            # On check si il y a des submodules a process
            if [[ -e $getSource_target/.gitmodules ]]
            then
                printf "updateSubmodules > $getSource_target ... "
                cd $getSource_target
                debug=`/usr/bin/git submodule update --recursive --init 2>&1`
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
                cd "$current_folder"
            fi

            # en cas de subapp
            if [ ! -z $conf_item_subdir ]
            then
                printf "Keep only ${conf_item_subdir} from ${getSource_target}... "
                cd ${getSource_target}
                pwd
                debug=`git filter-branch --prune-empty --subdirectory-filter ${conf_item_subdir} HEAD`
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
                cd "$current_folder"
            fi

            if [[ $environment != "DEV" ]]
            then
                # On supprime les metadatas de github
                printf "removeGit $getSource_target/.git* ... "
                debug=`/bin/rm -rf $getSource_target/.git* 2>&1`
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
            fi

        fi

        # Location : apps.owncloud.com
        # Alors wget sur le zip et unzip direct dans apps/
        if [[ $getSource_location =~ http://apps.owncloud.com/.* ]]
        then
            # On télécharge l'archive de l'app
            printf "getSource apps.owncloud.com > $getSource_target ... "
            debug=`/usr/bin/wget -x $getSource_location -O $getSource_target 2>&1`
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

            # On decompresse le tar
            printf "unTar $getSource_target ... "
            debug=`/bin/tar zxvf $getSource_target -C $output_folder/apps/ 2>&1`
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

            # On supprime l'archive une fois decompresse
            printf "removeTar $getSource_target ... "
            debug=`/bin/rm $getSource_target 2>&1`
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
        fi

        # Location : SVN
        # Alors on va dans le dossier et on fait un checkout
        if [[ $getSource_location =~ https://forge.subversion.cnrs.fr/.* ]]
        then
            # On télécharge l'archive de l'app
            printf "DL $getSource_target ... "
            debug=`/usr/bin/svn checkout $getSource_location $getSource_target 2>&1`
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

            if [[ $environment != "DEV" ]]
            then
                # On supprime les metadatas de svn
                printf "removeSvn $getSource_target/.svn* ... "
                debug=`/bin/rm -rf $getSource_target/.svn* 2>&1`
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
            fi
        fi

        # Location : local
        # Alors cp basique
        if [[ $getSource_location =~ ^/.*$ ]]
        then
            # On télécharge l'archive de l'app
            printf "DL $getSource_target ... "
            debug=`cp -pr $getSource_location $getSource_target 2>&1`
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
        fi
    }

#
# Traitement items
#
    # Init des repertoires (a cause de wget ..)
    #mkdir -p $output_folder/apps $output_folder/conf $output_folder/themes

    # Traitement des items
    # Pour chaque ligne du fichier de conf
    for conf_item in `cat "$conf_file"`
    do
        cd "$current_folder"
        conf_item_type=`echo $conf_item | cut -d "$conf_delimiter" -f 1`
        conf_item_location=`echo $conf_item | cut -d "$conf_delimiter" -f 2`
        conf_item_gittag=`echo $conf_item | cut -d "$conf_delimiter" -f 3`
        conf_item_subdir=`echo $conf_item | cut -d "$conf_delimiter" -f 4`

        # Type : Core
        # Path : $output_folder/
        if [[ $conf_item_type == "core" ]]
        then
            # Calcul de l'emplacement cible
            item_target=$output_folder
            # On appelle getSource
            getSource $conf_item_location $item_target $conf_item_gittag
        fi

        # Type : App
        # Path : $output_folder/apps/*
        if [[ $conf_item_type == "app" ]]
        then
            # Calcul de l'emplacement cible (soit le nom de l'app, soit le nom de l'archive)
            if [[ $conf_item_location =~ ^https?://.+/(.*)$ ]]
            then
                item_target=$output_folder/apps/${BASH_REMATCH[1]}
            fi

            # On appelle getSource
            getSource $conf_item_location $item_target $conf_item_gittag
        fi

        # Type : SubApp
        # Path : $output_folder/apps/*
        if [[ $conf_item_type == "subapp" ]]
        then
            item_target=$output_folder/apps/$conf_item_subdir

            # On appelle getSource
            getSource $conf_item_location $item_target $conf_item_gittag $conf_item_subdir
        fi

        # Type : Theme
        # Path : $output_folder/themes
        if [[ $conf_item_type == "theme" ]]
        then
            # Calcul de l'emplacement cible
            if [[ $conf_item_location =~ ^https?://.+/(.*)$ ]]
            then
                item_target=$output_folder/themes/${BASH_REMATCH[1]}
            fi

            getSource $conf_item_location $item_target $conf_item_gittag
        fi

        # Type : Script
        # Scripts executes pendant le build pour du patch par exemple
        if [[ $conf_item_type == "script" ]]
        then
            echo "externalScript $conf_item_location : "
            /bin/bash $conf_item_location $output_folder
        fi

        # Type : wayf
        # Path : $output_folder/wayf/*
        if [[ $conf_item_type == "wayf" ]]
        then
            item_target=$output_folder/wayf
            # On appelle getSource
            getSource $conf_item_location $item_target $conf_item_gittag
        fi

    # Fin for conf_item
    done

    # On positionne les droits sur les fichiers
    if [[ $environment != "TEST" ]]
    then
        cd "$current_folder"
        printf "CHOWN ${apacheUID} sur $output_folder ... "
        debug=`sudo /bin/chown ${apacheUID}:${apacheGID} "$output_folder" -R 2>&1`
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

        # On genere l'archive contenant le build
        cd "$current_folder"
        printf "TAR vers $output_folder-full.tar.gz ... "
        debug=`/bin/tar zcvf ${output_folder}-full.tar.gz "$output_folder" 2>&1`
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
    else
        # TEST env
        printf "Launch tests setup\n"
        /bin/bash "./tests/test-setup.sh" "$output_folder" "$appToTest"
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

        # TEST run
        printf "Run tests\n"
        /bin/bash "./tests/test-run.sh" "$output_folder" "$appToTest"
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
    fi
