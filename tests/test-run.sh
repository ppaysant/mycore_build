#!/bin/bash

#
# Params
#
    instance_folder="$1"
    appToTest="$2"
    PHP_BIN=/usr/bin/php
    PHPUNIT_BIN="phpunit"
    LOGS="../logs"

#
# Test phpunit existence
#
    # current_directory="$PWD"
    # cd "${instance_folder}"

    # if [ ! -x ${PHPUNIT_BIN} ]
    # then
    #     printf "PHPUNIT not found or not executable"
    #     exit 1
    # fi

#
# Run tests
#
    current_directory="$PWD"
    cd "${instance_folder}"

    #
    if [ -z ${appToTest} ]
    then
        ${PHPUNIT_BIN} -c phpunit-mycore.xml --log-junit="${LOGS}/junit.xml"
    else
        ${PHPUNIT_BIN} -c phpunit-${appToTest}.xml --log-junit="${LOGS}/${appToTest}-junit.xml"
    fi

    # come back
    cd "${current_directory}"
