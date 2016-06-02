#!/bin/bash

#
# Params
#
    instance_folder=$1
    appToTest=$2
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
    if [ -z ${appToTest} ]
    then
        cp ../tests/mycore-build.conf .
    else
        cp ../tests/mycore-build-${appToTest}.conf .
    fi

    cp ../tests/test-mycore-bootstrap.php .

    # come back
    cd "${current_directory}"
