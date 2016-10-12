#!/bin/bash

DEBUG="On" # DEBUG="On" if you want to display DEBUG messages

# UID et GID du serveur web
apacheUID="apache"
apacheGID="apache"

# RewriteBase
RewriteBase="/"

# binaires
PHP_BIN="/usr/bin/php"
NODE_BIN=node
NPM_BIN=npm
SUDO_BIN=/usr/bin/sudo
TAR_BIN=/usr/bin/tar

# conf
needed_php_modules="bz2 ctype curl date dom exif fileinfo ftp gd iconv intl mbstring pcre PDO pdo_mysql Phar posix readline sqlite3 xml"

#
# Helper
#

# Display help
function displayHelp {
    echo "Usage : ./mycore_build.sh [-b rewritebase] [-r] [-u UID] [-g GID] <conf_file> <output_folder> <[{PRODUCTION|DEV|TEST [app]}]>"
    echo "Build an instance of owncloud with some apps using a provided configuration file"
    echo ""
    echo "  -b                (optionnal - default: \"/\") the owncloud instance will be accessible via /rewritebase/ url"
    echo "  -r                (optionnal) mode RETRY, do not download already downloaded sources (verify presence of directory)"
    echo "  -u UID            (optionnal - default: \"apache\") user id used for the files"
    echo "  -g GID            (optionnal - default: \"apache\") user id used for the files"
    echo "  <conf_file>       (required) name of the configuration file (that sets the sources repositories)"
    echo "  <output_folder>   (required) name of the directory the owncloud instance will be built"
    echo "  PRODUCTION        production build, there will be no .git subdir, only the required files for owncloud"
    echo "  DEV               dev build, will keep .git subdirs"
    echo "  TEST              test build, after build, the script will launch phpunit with provided tests (cf tests directory for examples)"
    echo "  TEST <app>        test build, as TEST but will test only one app"
}

function displayMsg {
    level=$1
    shift
    msg=$*
    case $level in
        "ERROR")
            echo -e "[\e[31mERROR\e[0m]" $msg
            ;;
        "INFO")
            echo -e "[\e[32mINFO\e[0m]" $msg
            ;;
        "DEBUG")
            if [ ${DEBUG} == "On" ]
            then
                echo "[DEBUG]" $msg
            fi
            ;;
        *)
            echo $msg
            ;;
    esac
}

#
# Récupération des options
#
RETRY=0
OPTIND=1
while getopts ":bru:g:" opt; do
    case $opt in
        b)
            displayMSG "INFO" "RewriteBase " ${OPTARG}
            RewriteBase=${OPTARG}
            ;;
        r)
            displayMsg "INFO" "Mode RETRY active"
            RETRY=1
            ;;
        u)
            apacheUID=${OPTARG}
            ;;
        g)
            apacheGID=${OPTARG}
            ;;
        ?)
            displayMsg "ERROR" "Invalid option :" ${OPTARG}
            displayHelp
            ;;
    esac
done

shift $((OPTIND - 1))
[ "$1" = "--" ] && shift

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
# Checks paramètres
#

    displayMsg "INFO" "Server uid" ${apacheUID} "and gid" ${apacheGID}

    # Verif dossier destination
    if [[ $output_folder == "" || $conf_file == "" ]]
    then
        displayMsg "ERROR" "File configuration and output directory must be provided"
        displayHelp
        exit
    else
        displayMsg "INFO" "Configuration file: "${conf_file}
        displayMsg "INFO" "Output folder: "${output_folder}
    fi

    # On empeche d'ecraser un build precedent
    if [[ -d ${output_folder} && ! ${RETRY} -eq 1 ]]
    then
        displayMsg "ERROR" "The directory ${output_folder} already exist!"
        displayHelp
        exit
    fi

    # Verif dossier destination
    if [[ $environment != "" ]]
    then
        if [[ $environment == "PRODUCTION" || $environment == "DEV" || $environment == "TEST" ]]
         then
            displayMsg "INFO" "Parameters OK"
        else
            displayMsg "ERROR" "You MUST specify target mode : PRODUCTION, TEST (w/o git/svn dirs),  or DEV (with git/svn dirs)"
            displayHelp
            exit
        fi
    else
        if [[ $environment == "" ]]
        then
            displayMsg "INFO" "Target mode not provided, set by default to PRODUCTION"
            environment="PRODUCTION"
        fi
    fi

#
# Check des utilitaires nécessaires
#

    #  wget
    debug=`which wget`
    if [[ $? -ge "1" ]]
    then
        displayMsg "ERROR" "command wget not found. The tool 'wget' MUST be installed."
        exit
    else
        displayMsg "INFO" "command wget found. Ok!"
    fi

    #  sudo
    debug=`which sudo`
    if [[ $? -ge "1" ]]
    then
        displayMsg "ERROR" "command sudo not found. The tool 'sudo' MUST be installed (and configured)."
        exit
    else
        displayMsg "INFO" "command sudo found. Ok!"
    fi

    #  make
    debug=`which make`
    if [[ $? -ge "1" ]]
    then
        displayMsg "ERROR" "command make not found. The tool 'make' MUST be installed."
        exit
    else
        displayMsg "INFO" "command make found. Ok!"
    fi

    #  PHP
    debug=`${PHP_BIN} -r 'if (PHP_MAJOR_VERSION > 5 OR ( PHP_MAJOR_VERSION == 5 AND PHP_MINOR_VERSION >= 6 )) { exit(0); } else { exit(1); }'`
    if [[ $? -ge "1" ]]
    then
        displayMsg "ERROR" "PHP not found or obsolete version. The minimal version of PHP is PHP 5.6. Please set PHP binary path at top of this script."
        exit
    else
        displayMsg "INFO" "command PHP found and correct version. Ok!"
    fi

    #  PHP modules
    is_missing_module=0
    missing_modules=""
    for module in ${needed_php_modules}
    do
        debug=`${PHP_BIN} -m | grep ${module}`
        if [[ $? -ge "1" ]]
        then
            displayMsg "ERROR" "PHP module ${module} not found."
            is_missing_module=1
            missing_modules="${missing_modules} ${module}"
        else
            displayMsg "INFO" "PHP module ${module} found. Ok!"
        fi
    done

    if [[ ! ${is_missing_module} -eq 0 ]]
    then
        displayMsg "ERROR" "Some PHP modules are missing: ${missing_modules}, please install them."
        exit
    fi

    # nodejs
    debug=`${NODE_BIN} -v 2&>/dev/null`
    if [ $? -ge "1" ]
    then
        displayMsg "ERROR" "command nodejs not found. Please install nodejs (https://github.com/creationix/nvm)."
        exit
    else
        displayMsg "INFO" "command nodejs found. Ok!"
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

        if [[ -d ${getSource_target} ]]
        then
            displayMsg "INFO" "${getSource_target} already exists, going next step."
            return
        fi

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

            displayMsg "INFO" "getSource github > $getSource_target ... "
            debug=`/usr/bin/git clone --branch $getSource_tag ${gitDepth} $getSource_location $getSource_target 2>&1`
            if [[ $? -ge "1" ]]
            then
                displayMsg "ERROR"
                displayMsg $debug
                exit
            else
                displayMsg "INFO" "OK"
            fi

            # On check si il y a des submodules a process
            if [[ -e $getSource_target/.gitmodules ]]
            then
                displayMsg "INFO" "updateSubmodules > $getSource_target ... "
                cd $getSource_target
                debug=`/usr/bin/git submodule update --recursive --init 2>&1`
                if [[ $? -ge "1" ]]
                then
                    displayMsg "ERROR" $debug
                    exit
                else
                    displayMsg "INFO" "OK"
                fi
                cd "$current_folder"
            fi

            # en cas de subapp
            if [ ! -z $conf_item_subdir ]
            then
                displayMsg "INFO" "Keep only ${conf_item_subdir} from ${getSource_target}... "
                cd ${getSource_target}
                pwd
                debug=`git filter-branch --prune-empty --subdirectory-filter ${conf_item_subdir} HEAD`
                if [[ $? -ge "1" ]]
                then
                    displayMsg "ERROR" $debug
                    exit
                else
                    displayMsg "INFO" "OK"
                fi
                cd "$current_folder"
            fi

            if [[ $environment != "DEV" ]]
            then
                # On supprime les metadatas de github
                displayMsg "INFO" "removeGit $getSource_target/.git* ... "
                debug=`/bin/rm -rf $getSource_target/.git* 2>&1`
                if [[ $? -ge "1" ]]
                then
                    displayMsg "ERROR" $debug
                    exit
                else
                    displayMsg "INFO" "OK"
                fi
            fi

        fi

        # Location : apps.owncloud.com
        # Alors wget sur le zip et unzip direct dans apps/
        if [[ $getSource_location =~ http://apps.owncloud.com/.* ]]
        then
            # On télécharge l'archive de l'app
            displayMsg "INFO" "getSource apps.owncloud.com > $getSource_target ... "
            debug=`/usr/bin/wget -x $getSource_location -O $getSource_target 2>&1`
            if [[ $? -ge "1" ]]
            then
                displayMsg "ERROR" $debug
                exit
            else
                displayMsg "INFO" "OK"
            fi

            # On decompresse le tar
            displayMsg "INFO" "unTar $getSource_target ... "
            debug=`/bin/tar zxvf $getSource_target -C $output_folder/apps/ 2>&1`
            if [[ $? -ge "1" ]]
            then
                displayMsg "ERROR" $debug
                exit
            else
                displayMsg "INFO" "OK"
            fi

            # On supprime l'archive une fois decompresse
            displayMsg "INFO" "remove tar $getSource_target ... "
            debug=`/bin/rm $getSource_target 2>&1`
            if [[ $? -ge "1" ]]
            then
                displayMsg "ERROR" $debug
                exit
            else
                displayMsg "INFO" "OK"
            fi
        fi

        # Location : SVN
        # Alors on va dans le dossier et on fait un checkout
        if [[ $getSource_location =~ https://forge.subversion.cnrs.fr/.* ]]
        then
            # On télécharge l'archive de l'app
            displayMsg "INFO" "DL $getSource_target ... "
            debug=`/usr/bin/svn checkout $getSource_location $getSource_target 2>&1`
            if [[ $? -ge "1" ]]
            then
                displayMsg "ERROR" $debug
                exit
            else
                displayMsg "INFO" "OK"
            fi

            if [[ $environment != "DEV" ]]
            then
                # On supprime les metadatas de svn
                displayMsg "INFO" "removeSvn $getSource_target/.svn* ... "
                debug=`/bin/rm -rf $getSource_target/.svn* 2>&1`
                if [[ $? -ge "1" ]]
                then
                    displayMsg "ERROR" $debug
                    exit
                else
                    displayMsg "INFO" "OK"
                fi
            fi
        fi

        # Location : local
        # Alors cp basique
        if [[ $getSource_location =~ ^/.*$ ]]
        then
            # On télécharge l'archive de l'app
            displayMsg "INFO" "DL $getSource_target ... "
            debug=`cp -pr $getSource_location $getSource_target 2>&1`
            if [[ $? -ge "1" ]]
            then
                displayMsg "ERROR" $debug
                exit
            else
                displayMsg "INFO" "OK"
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
    displayMsg "INFO" "Downloading files"
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
            displayMsg "DEBUG" "Download core component at ${conf_item_location} branch ${conf_item_gittag} to ${item_target}"
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
            displayMsg "DEBUG" "Download app at ${conf_item_location} branch ${conf_item_gittag} to ${item_target}"
            getSource $conf_item_location $item_target $conf_item_gittag
        fi

        # Type : SubApp
        # Path : $output_folder/apps/*
        if [[ $conf_item_type == "subapp" ]]
        then
            item_target=$output_folder/apps/$conf_item_subdir

            # On appelle getSource
            displayMsg "DEBUG" "Download sub-app at ${conf_item_location} / ${conf_item_subdir} branch ${conf_item_gittag} to ${item_target}"
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

            displayMsg "DEBUG" "Download theme at ${conf_item_location} branch ${conf_item_gittag} to ${item_target}"
            getSource $conf_item_location $item_target $conf_item_gittag
        fi

        # Type : Script
        # Scripts executes pendant le build pour du patch par exemple
        if [[ $conf_item_type == "script" ]]
        then
            displayMsg "INFO" "externalScript $conf_item_location : "
            /bin/bash $conf_item_location $output_folder
        fi

        # Type : wayf
        # Path : $output_folder/wayf/*
        if [[ $conf_item_type == "wayf" ]]
        then
            item_target=$output_folder/wayf
            # On appelle getSource
            displayMsg "DEBUG" "Download wayf at ${conf_item_location} branch ${conf_item_gittag} to ${item_target}"
            getSource $conf_item_location $item_target $conf_item_gittag
        fi

    # Fin for conf_item
    done

    # If RETRY mode, then reset the access rights (to get "make" work)
    if [[ ${RETRY} -eq 1 && -d ${output_folder} ]]
    then
        displayMsg "INFO" "Give current user the access rights to ${output_folder} (needed by BUILD step)"
        debug=`${SUDO_BIN} /bin/chown ${USER} "$output_folder" -R 2>&1`
        if [[ $? -ge "1" ]]
        then
            displayMsg "ERROR" $debug
            exit
        else
            displayMsg "INFO" "OK"
        fi
    fi

    # Lancer la commande de build (le makefile)
    cd "$output_folder"
    if [[ ${USER} == 'root' ]]
    then
        displayMsg "INFO" "Running as root, so I change the owncloud Makefile to allow use of bower in root mode"
        debug=`sed -ie "s/\(\\\$(BOWER) \(install\|update\)\)/\1 --allow-root/" Makefile`
        if [[ $? -ge "1" ]]; then
            displayMsg "ERROR" $debug
            exit
        else
            displayMsg "INFO" "OK"
        fi
    fi
    displayMsg "INFO" "MAKE in $output_folder ... "
    debug=`make`
    if [[ $? -ge "1" ]]
    then
        displayMsg "ERROR" $debug
        exit
    else
        displayMsg "INFO" "OK"
    fi

    # En mode DEV ou PRODUCTION
    if [[ $environment != "TEST" ]]
    then
        # On positionne les droits sur les fichiers
        cd "$current_folder"
        displayMsg "INFO" "CHOWN ${apacheUID} sur $output_folder ... "
        debug=`${SUDO_BIN} /bin/chown ${apacheUID}:${apacheGID} "$output_folder" -R 2>&1`
        if [[ $? -ge "1" ]]
        then
            displayMsg "ERROR" $debug
            exit
        else
            displayMsg "INFO" "OK"
        fi

        # On passe le .htaccess en .htaccess.sample
        cd "$current_folder"
        if [[ ! ${RETRY} -eq 1 ]]
        then
            displayMsg "INFO" "Renommage du htaccess ... "
            debug=`${SUDO_BIN} /bin/mv "$output_folder/.htaccess" "$output_folder/.htaccess.sample" 2>&1`
            if [[ $? -ge "1" ]]
            then
                displayMsg "ERROR" $debug
                exit
            else
                displayMsg "INFO" "OK"
            fi
        fi

        # On genere l'archive contenant le build
        cd "$current_folder"

        if [[ -f ${output_folder}-full.tar.gz ]]
        then
            if [[ ${RETRY} -eq 1 ]]
            then
                debug=`rm -f "./${output_folder}-full.tar.gz"`
                if [[ $? -ge "1" ]]
                then
                    displayMsg "ERROR" "impossible de supprimer l'archive ./${output_folder}-full.tar.gz."
                    displayMsg "ERROR" $debug
                    exit
                else
                    displayMsg "INFO" "Suppression de la précédente archive ${output_folder}-full.tar.gz."
                fi
            else
                displayMsg "ERROR" "Le fichier ${output_folder}-full.tar.gz existe déjà. Supprimez le fichier ou relancer en mode RETRY (option -r)."
                exit
            fi
        fi

        displayMsg "INFO" "TAR vers $output_folder-full.tar.gz ... "
        debug=`${SUDO_BIN} /bin/tar zcvf ${output_folder}-full.tar.gz "$output_folder" 2>&1`
        if [[ $? -ge "1" ]]
        then
            displayMsg "ERROR" $debug
            exit
        else
            displayMsg "INFO" "OK"
        fi
    # En mode TEST
    else
        # Remettre l'app en "non installé" si mode RETRY
        cd "${current_folder}/${output_folder}"
        if [[ -w "config/config.php" && ${RETRY} -eq 1 ]]
        then
            # in config.php, set 'installed' => false
            debug=`sed -i "s/'installed' => true/'installed' => false/" config/config.php`
            if [[ $? -ge "1" ]]
            then
                displayMsg "ERROR" $debug
                exit
            else
                displayMsg "INFO" "OK"
            fi
        fi

        cd "$current_folder"
        displayMsg "INFO" "Launch tests setup\n"
        /bin/bash "./tests/test-setup.sh" "$output_folder" "$appToTest"
        if [[ $? -ge "1" ]]
        then
            displayMsg "ERROR" $debug
            exit
        else
            displayMsg "INFO" "OK"
        fi

        # TEST run
        displayMsg "INFO" "Run tests\n"
        /bin/bash "./tests/test-run.sh" "$output_folder" "$appToTest"
        if [[ $? -ge "1" ]]
        then
            displayMsg "ERROR" $debug
            exit
        else
            displayMsg "INFO" "OK"
        fi
    fi

displayMsg "INFO" "========= THE END ========="
