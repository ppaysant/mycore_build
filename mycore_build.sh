#!/bin/bash

# DEBUG="On" if you want to display DEBUG messages
DEBUG="On"

# UID et GID du serveur web
apacheUID="apache"
apacheGID="apache"
DATA_DIR=""

# RewriteBase
RewriteBase="/"

# binaires
PHP_BIN="/usr/bin/php"
NODE_BIN=node
NPM_BIN=npm
SUDO_BIN=/usr/bin/sudo
TAR_BIN=/usr/bin/tar
MYSQL_BIN=/usr/bin/mysql

# Load conf parameters
source ./mycore_build_settings.conf

# PHP modules
needed_php_modules="bz2 ctype curl date dom exif fileinfo ftp gd iconv intl mbstring pcre PDO pdo_mysql Phar posix readline sqlite3 xml"

#
# Helper
#

# Display help
function displayHelp {
    echo "Usage : ./mycore_build.sh [-b rewritebase] [-r] [-u UID] [-g GID] -d <datadirectory> -n <databasename> <conf_file> <output_folder> <[{PRODUCTION|DEV|TEST [app]}]>"
    echo "Build an instance of owncloud with some apps using a provided configuration file"
    echo ""
    echo "  -r                (optionnal) mode RETRY, do not download already downloaded sources (verify presence of directory)"
    echo "  -u UID            (optionnal - default: \"apache\") user id used for the files"
    echo "  -g GID            (optionnal - default: \"apache\") user id used for the files"
    echo "  -b                (optionnal - default: \"/\") the owncloud instance will be accessible via /rewritebase url"
    echo "  -d                (required for PRODUCTION or DEV) Data directory that will be created for the owncloud instance to use"
    echo "  -n                (required for PRODUCTION or DEV) Database name that will be created for the owncloud instance to use"
    echo "  <conf_file>       (required) name of the configuration file (that sets the sources repositories)"
    echo "  <output_folder>   (required) name of the directory the owncloud instance will be built"
    echo "  PRODUCTION        production build, there will be no .git subdir, only the required files for owncloud"
    echo "  DEV               dev build, will keep .git subdirs"
    echo "  TEST              test build, after build, the script will launch phpunit with provided tests (cf tests directory for examples)"
    echo "  TEST <app>        test build, as TEST but will test only one app"
}

function displayMsg {
    if [[ $# -lt 2 ]]
    then
        echo -e "[\e[31mFATAL\e[0m]" "incorrect use of displayMsg function which needs at least two parameters.. "
        echo "Please contact the script author with this information: " $(caller)
        exit
    fi

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

function manageError {
    if [[ ! $# -eq "5" ]]
    then
        echo -e "[\e[31mFATAL\e[0m]" "incorrect use of manageError function which needs exactly 5 parameters ($# given). "
        echo "Please contact the script author with this information: " $(caller)
        exit
    fi

    errorCode=$1
    failMsg=$2
    showHelp=$3
    exitOnError=$4
    successMsg=$5

    if [[ ${errorCode} -ge "1" ]]
    then
        displayMsg "ERROR" $failMsg

        if [[ ${showHelp} -eq "1" ]]
        then
            displayHelp
        fi

        if [[ ${exitOnError} -eq "1" ]]
        then
            exit 1
        fi
    else
        displayMsg "INFO" ${successMsg}
    fi
}

#
# Récupération des options
#
RETRY=0
OPTIND=1
while getopts ":b:ru:g:n:d:" opt; do
    case $opt in
        b)
            displayMsg "INFO" "RewriteBase: " ${OPTARG}
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
        n)
            displayMsg "INFO" "Database name: ${OPTARG}"
            DATABASE_NAME=${OPTARG}
            ;;
        d)
            displayMsg "INFO" "Data directory name: ${OPTARG}"
            DATA_DIR=${OPTARG}
            ;;
        ?)
            displayMsg "ERROR" "Invalid option: " ${OPTARG}
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
        displayMsg "ERROR" "The directory ${output_folder} already exist! Maybe you want to use -r (RETRY) mode ?"
        displayHelp
        exit 1
    fi

    # Verif dossier destination
    if [[ $environment != "" ]]
    then
        if [[ $environment == "PRODUCTION" || $environment == "DEV" || $environment == "TEST" ]]
         then
            displayMsg "INFO" "Parameters OK"
        else
            displayMsg "ERROR" "You MUST specify target mode : PRODUCTION or TEST (w/o git/svn dirs),  or DEV (with git/svn dirs)."
            displayHelp
            exit 1
        fi
    else
        if [[ $environment == "" ]]
        then
            displayMsg "INFO" "Target mode not provided, set by default to PRODUCTION."
            environment="PRODUCTION"
        fi
    fi

    # Dossier data de l'instance, vu qu'on n'utilise pas le data par défaut
    if [[ ${DATA_DIR} == "" && $environment != "TEST" ]]
    then
        displayMsg "ERROR" "DATA_DIR (for owncloud instance) MUST be provided (with -d option) for ${environment} mode."
        exit 1
    else
        displayMsg "INFO" "DATA_DIR set to ${DATA_DIR}."
    fi

    # Database
    if [[ ${DATABASE_NAME} == "" && $environment != "TEST" ]]
    then
        displayMsg "ERROR" "The database name MUST be provided (with -n option) for ${environment} mode."
        exit 1
    else
        displayMsg "INFO" "DATABASE_NAME set to ${DATABASE_NAME}."
    fi

    # Admin user
    if [[ ${ADMIN_USER} == "" || ${ADMIN_PASS} == "" || ${ADMIN_EMAIL} == "" ]]
    then
        displayMsg "ERROR" "Missing some ADMIN info (see mycore_build_settings.conf)."
        exit 1
    else
        displayMsg "INFO" "ADMIN: ${ADMIN_USER} / ${ADMIN_EMAIL} / (password set)."
    fi

#
# Check des utilitaires nécessaires
#
    # cmde=$1 failMsg=$2 showHelp=$3 exitOnError=$4 successMsg=$5

    #  wget
    debug=`which wget`
    manageError $? "command wget not found. The tool 'wget' MUST be installed." 0 1 "command wget found. Ok!"

    #  sudo
    debug=`which sudo`
    manageError $? "command sudo not found. The tool 'sudo' MUST be installed (and configured)." 0 1 "command sudo found. Ok!"

    #  make
    debug=`which make`
    manageError $? "command make not found. The tool 'make' MUST be installed." 0 1 "command make found. Ok!"

    #  PHP
    debug=`${PHP_BIN} -r 'if (version_compare(PHP_VERSION, "5.6.0", ">=")) { exit(0); } else { exit(1); }'`
    manageError $? \
        "PHP not found or obsolete version. The minimal version of PHP is PHP 5.6. Please set PHP binary path at top of this script." \
        0 \
        1 \
        "command PHP found and correct version. Ok!"

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
        exit 1
    fi

    # nodejs
    debug=`${NODE_BIN} -v &>/dev/null`
    manageError $? "command nodejs not found. Please install nodejs (https://github.com/creationix/nvm)." 0 1 "command nodejs found. Ok!"

    # mysql command, not needed for test environnement
    if [[ $environment != "TEST" ]]
    then
        debug=`${MYSQL_BIN} --version &>/dev/null`
        manageError $? "command mysql not found. Please be sure to correctly edit mysql path at top of this script." 0 1 "command mysql found. OK!"

        # test connection and database presence
        displayMsg "DEBUG" "${MYSQL_BIN} -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASS} -e \"select version();\" &>/dev/null"
        debug=`${MYSQL_BIN} -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASS} -e "select version();" &>/dev/null`
        manageError $? "can't connect to database." 0 1 "can connect to database. Ok!"

        displayMsg "DEBUG" "${MYSQL_BIN} -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASS} ${DATABASE_NAME} -e \"show tables;\" &>/dev/null"
        debug=`${MYSQL_BIN} -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASS} ${DATABASE_NAME} -e "show tables;" &>/dev/null`
        manageError $? "can't access to database tables." 0 1 "can access to database tables. Ok!"
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
            manageError $? "${debug}" 0 1 "OK"

            # On check si il y a des submodules a process
            if [[ -e $getSource_target/.gitmodules ]]
            then
                displayMsg "INFO" "updateSubmodules > $getSource_target ... "
                cd $getSource_target

                debug=`/usr/bin/git submodule update --recursive --init 2>&1`
                manageError $? "${debug}" 0 1 "OK"

                cd "$current_folder"
            fi

            # en cas de subapp
            if [ ! -z $conf_item_subdir ]
            then
                displayMsg "INFO" "Keep only ${conf_item_subdir} from ${getSource_target}... "
                cd ${getSource_target}
                pwd
                debug=`git filter-branch --prune-empty --subdirectory-filter ${conf_item_subdir} HEAD`
                manageError $? "${debug}" 0 1 "OK"
                cd "$current_folder"
            fi

            if [[ $environment != "DEV" ]]
            then
                # On supprime les metadatas de github
                displayMsg "INFO" "removeGit $getSource_target/.git* ... "
                debug=`/bin/rm -rf $getSource_target/.git* 2>&1`
                manageError $? "${debug}" 0 1 "OK"
            fi

        fi

        # Location : apps.owncloud.com
        # Alors wget sur le zip et unzip direct dans apps/
        if [[ $getSource_location =~ http://apps.owncloud.com/.* ]]
        then
            # On télécharge l'archive de l'app
            displayMsg "INFO" "getSource apps.owncloud.com > $getSource_target ... "
            debug=`/usr/bin/wget -x $getSource_location -O $getSource_target 2>&1`
            manageError $? "${debug}" 0 1 "OK"

            # On decompresse le tar
            displayMsg "INFO" "unTar $getSource_target ... "
            debug=`/bin/tar zxvf $getSource_target -C $output_folder/apps/ 2>&1`
            manageError $? "${debug}" 0 1 "OK"

            # On supprime l'archive une fois decompresse
            displayMsg "INFO" "remove tar $getSource_target ... "
            debug=`/bin/rm $getSource_target 2>&1`
            manageError $? "${debug}" 0 1 "OK"
        fi

        # Location : SVN
        # Alors on va dans le dossier et on fait un checkout
        if [[ $getSource_location =~ https://forge.subversion.cnrs.fr/.* ]]
        then
            # On télécharge l'archive de l'app
            displayMsg "INFO" "DL $getSource_target ... "
            debug=`/usr/bin/svn checkout $getSource_location $getSource_target 2>&1`
            manageError $? "${debug}" 0 1 "OK"

            if [[ $environment != "DEV" ]]
            then
                # On supprime les metadatas de svn
                displayMsg "INFO" "removeSvn $getSource_target/.svn* ... "
                debug=`/bin/rm -rf $getSource_target/.svn* 2>&1`
                manageError $? "${debug}" 0 1 "OK"
            fi
        fi

        # Location : local
        # Alors cp basique
        if [[ $getSource_location =~ ^/.*$ ]]
        then
            # On télécharge l'archive de l'app
            displayMsg "INFO" "DL $getSource_target ... "
            debug=`cp -pr $getSource_location $getSource_target 2>&1`
            manageError $? "${debug}" 0 1 "OK"
        fi
    }

#
# Traitement items
#
    # Init des repertoires (a cause de wget ..)
    # mkdir -p $output_folder/apps $output_folder/conf $output_folder/themes

    # Traitement des items
    # Pour chaque ligne du fichier de conf
    displayMsg "INFO" "Downloading files"
    for conf_item in `cat "$conf_file"`
    do
        displayMsg "DEBUG" "processing (for download): ${conf_item}"

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

#
# Build phase
#
    # If RETRY mode, then reset the access rights (to get "make" work)
    if [[ ${RETRY} -eq 1 && -d ${output_folder} ]]
    then
        displayMsg "INFO" "Give current user the access rights to ${output_folder} (needed by BUILD step)"
        debug=`${SUDO_BIN} /bin/chown ${USER} "$output_folder" -R 2>&1`
        manageError $? "${debug}" 0 1 "OK"
    fi

    # Lancer la commande de build (le makefile)
    cd "$output_folder"
    if [[ ${USER} == 'root' ]] # maybe not the best test...
    then
        displayMsg "INFO" "Running as root, so I change the owncloud Makefile to allow use of bower in root mode"
        debug=`sed -i -e "s/\(\\\$(BOWER) \(install\|update\)\)/\1 --allow-root/" Makefile`
        manageError $? "${debug}" 0 1 "OK"
    fi
    displayMsg "INFO" "MAKE in $output_folder ... "
    debug=`make`
    manageError $? "${debug}" 0 1 "Make build OK"

    # En mode DEV ou PRODUCTION
    if [[ $environment != "TEST" ]]
    then
        # creation du DATA_DIR si nécessaire
        if [[ ! -d ${DATA_DIR} ]]
        then
            displayMsg "INFO" "Creating DATA_DIR directory..."
            debug=`mkdir ${DATA_DIR}`
            manageError $? "Can't create DATA_DIR directory." 0 1 "OK"
        fi

        # On positionne les droits sur les fichiers
        cd "$current_folder"
        displayMsg "INFO" "CHOWN ${apacheUID} sur $output_folder ... "
        debug=`${SUDO_BIN} /bin/chown ${apacheUID}:${apacheGID} "$output_folder" -R 2>&1`
        manageError $? "${debug}" 0 1 "OK"

        # On passe le .htaccess en .htaccess.sample
        cd "$current_folder"
        if [[ ! ${RETRY} -eq 1 ]]
        then
            displayMsg "INFO" "Renommage du htaccess ... "
            debug=`${SUDO_BIN} /bin/mv "$output_folder/.htaccess" "$output_folder/.htaccess.sample" 2>&1`
            manageError $? "${debug}" 0 1 "OK"
        fi

        # Install owncloud via occ
        debug=`grep "'installed' => true" "${output_folder}/config/config.php" &>/dev/null`
        if [[ $? -ge "1" ]]
        then
            cd "$output_folder"
            displayMsg "INFO" "Launching owncloud install via occ ..."
            displayMsg "DEBUG" "${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ maintenance:install -vvv
                --database=\"${DATABASE_TYPE}\" --database-name=\"${DATABASE_NAME}\" --database-host=\"${DATABASE_HOST}\"
                --database-user=\"${DATABASE_USER}\" --database-pass=\"${DATABASE_PASS}\" --database-table-prefix=\"${DATABASE_TABLE_PREFIX}\"
                --admin-user=\"${ADMIN_USER}\" --admin-pass=\"${ADMIN_PASS}\" --data-dir=\"${DATA_DIR}\""
            debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ maintenance:install -vvv \
                --database="${DATABASE_TYPE}" --database-name="${DATABASE_NAME}" --database-host="${DATABASE_HOST}" \
                --database-user="${DATABASE_USER}" --database-pass="${DATABASE_PASS}" --database-table-prefix="${DATABASE_TABLE_PREFIX}" \
                --admin-user="${ADMIN_USER}" --admin-pass="${ADMIN_PASS}" --data-dir="${DATA_DIR}" 2>&1`
            manageError $? "ownCloud install failed: ${debug}" 0 1 "ownCloud install successfully done."
        else
            displayMsg "INFO" "owncloud already \"installed\", going next step."
        fi

        # Prepare the htaccess
        debug=`grep "htaccess.RewriteBase" "${output_folder}/config/config.php"`
        if [[ $? -ge "1" ]]
        then
            displayMsg "INFO" "Preparing htaccess..."
            debug=`sed -i -e "s#\(.*dbpassword.*\)#\1\n  'htaccess.RewriteBase' => \"${RewriteBase}\",#" "${output_folder}/config/config.php" 2>&1`
            manageError $? "${debug}" 0 1 "OK"
        fi

        # Update the htaccess
        displayMsg "INFO" "Updating htaccess"
        cd "$output_folder"
        debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ maintenance:update:htaccess 2>&1`
        manageError $? "${debug}" 0 1 "OK"

        # ############ SPECIFIC ###############

        if [[ ! ${SPECIFIC_SHELL} -eq "" ]]
        then
            source "${SPECIFIC_SHELL}"
        fi

        # ############ END SPECIFIC ###############

        # On genere l'archive tgz contenant le build final
        cd "$current_folder"

        if [[ $environment == "PRODUCTION" ]]
        then
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
            manageError $? "${debug}" 0 1 "OK"
        fi
    # En mode TEST
    else
        # Remettre l'app en "non installé" si mode RETRY
        cd "${current_folder}/${output_folder}"
        if [[ -w "config/config.php" && ${RETRY} -eq 1 ]]
        then
            # in config.php, set 'installed' => false
            debug=`sed -i "s/'installed' => true/'installed' => false/" config/config.php`
            manageError $? "${debug}" 0 1 "OK"
        fi

        cd "$current_folder"
        displayMsg "INFO" "Launch tests setup\n"
        /bin/bash "./tests/test-setup.sh" "$output_folder" "$appToTest"
        manageError $? "setup script failed." 0 1 "end of setup script"

        # TEST run
        displayMsg "INFO" "Run tests\n"
        /bin/bash "./tests/test-run.sh" "$output_folder" "$appToTest"
        manageError $? "test script failed." 0 1 "end of test script"
    fi

displayMsg "INFO" "========= THE END ========="
