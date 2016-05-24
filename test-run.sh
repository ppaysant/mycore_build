#!/bin/bash

#
# Params
#
    instance_folder="$1"
    PHP_BIN=/usr/bin/php
    PHPUNIT_BIN="phpunit"

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
    ${PHPUNIT_BIN} -c test-mycore.conf

    # come back
    cd "${current_directory}"
