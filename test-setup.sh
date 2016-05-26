#!/bin/bash

#
# Params
#
    instance_folder=$1
    PHP_BIN=/usr/bin/php
    LOGS="./logs"

#
# Create logs folder if non existent
#
    if [ -e ${LOGS} ]
    then
        mkdir ${LOGS}
    fi

#
# Launch instance installation
#
    current_directory="$PWD"
    cd "${instance_folder}"
    DATADIR=$PWD/data

    # Prepare oncloud install
    /bin/chmod -R 777 config
    /bin/chmod -R 777 apps

    # Install ownCloud with sqlite
    ${PHP_BIN} ./occ maintenance:install -vvv \
        --database="sqlite" --database-name="test_mycore.sqlite" --database-host="localhost" \
        --database-user="admin" --database-pass=owncloud --database-table-prefix=oc_ \
        --admin-user="admin" --admin-pass=admin --data-dir="${DATADIR}"

    # get PHPUNIT xml conf
    cp ../test-mycore.conf .

    # come back
    cd "${current_directory}"