# ############ SPECIFIC CNRS ###############

# THEME config
# Changing theme to "mycore"
if [[ -d "${output_folder}/themes/mycore" ]]
then
    cd "$output_folder"
    displayMsg "INFO" "Changing theme to mycore"
    debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ config:system:set theme --value="mycore"`
    manageError $? "${debug}" 0 1 "OK"
fi

# WAYF config
if [[ -d "${output_folder}/wayf" ]]
then
    # Modify .htaccess to authorize access to the wayf directory
    displayMsg "INFO" "Adding wayf access in htaccess"
    debug=`sed -i -e "s#\(.*ocs-provider.*\)#\1\n  RewriteCond %{REQUEST_FILENAME} \!wayf/#" ${output_folder}/.htaccess`
    manageError $? "${debug}" 0 1 "OK"

    # Adapt wayf providers to partage-rec IdP
    displayMsg "INFO" "Adapt wayf providers to partage-rec IdP"
    #debug=`printf '<?php'"\n"'$IDProviders["https://janus-rec.cnrs.fr/idp/shibboleth"]["SSO"] = "https://janus-rec.cnrs.fr/idp/profile/Shibboleth/SSO";'"\n"'$IDProviders["https://janus-rec.cnrs.fr/idp/shibboleth"]["Name"] = "Personnel des unités CNRS";'"\n"'$IDProviders["https://janus-rec-ext.cnrs.fr/idp-ext/shibboleth"]["SSO"] = "https://janus-rec-ext.cnrs.fr/idp-ext/profile/Shibboleth/SSO";'"\n"'$IDProviders["https://janus-rec-ext.cnrs.fr/idp-ext/shibboleth"]["Name"] = "Comptes spéciaux";'"\n"'?>' > ${output_folder}/wayf/IDProvider.conf.php 2>&1`
    debug=`cat > ${output_folder}/wayf/IDProvider.conf.php <<\END
<?php
$IDProviders["https://janus-rec.cnrs.fr/idp/shibboleth"]["SSO"] = "https://janus-rec.cnrs.fr/idp/profile/Shibboleth/SSO";
$IDProviders["https://janus-rec.cnrs.fr/idp/shibboleth"]["Name"] = "Personnel des unités CNRS";
$IDProviders["https://janus-rec-ext.cnrs.fr/idp-ext/shibboleth"]["SSO"] = "https://janus-rec-ext.cnrs.fr/idp-ext/profile/Shibboleth/SSO";
$IDProviders["https://janus-rec-ext.cnrs.fr/idp-ext/shibboleth"]["Name"] = "Comptes spéciaux";

END`
    manageError $? "${debug}" 0 1 "OK"

    # Adapt wayf configuration
    displayMsg "INFO" "Adapt wayf configuration file for federation URL"
    debug=`sed -i "s#federationURL = '.*'#federationURL = '${baseURL}/'#" ${output_folder}/wayf/config.php 2>&1`
    manageError $? "${debug}" 0 1 "OK"

    displayMsg "INFO" "Adapt wayf configuration file for logfile"
    debug=`sed -i 's#$WAYFLogFile#// $WAYFLogFile#' ${output_folder}/wayf/config.php 2>&1`
    manageError $? "${debug}" 0 1 "OK"

    displayMsg "INFO" "Adapt wayf configuration file for metadataFile"
    debug=`sed -i 's#$metadataFile#// $metadataFile#' ${output_folder}/wayf/config.php 2>&1`
    manageError $? "${debug}" 0 1 "OK"

    # Adapt wayf embedded js to used IdP
    displayMsg "INFO" "Adapt wayf embeddedWAYF.js to used IdP"
    debug=`sed -i "s#wayf_URL = \".*\"#wayf_URL = \"${baseURL}${RewriteBase}/wayf/index.php\"#" ${output_folder}/wayf/js/embeddedWAYF.js 2>&1`
    manageError $? "${debug}" 0 1 "OK"

    # Adapt wayf embeddedWAYF.js to declared SP
    displayMsg "INFO" "Adapt wayf embeddedWAYF.js to declared SP"
    debug=`sed -i "s#wayf_sp_entityID = \".*\"#wayf_sp_entityID = \"${baseURL}\"#" ${output_folder}/wayf/js/embeddedWAYF.js 2>&1`
    manageError $? "${debug}" 0 1 "OK"

    # Adapt wayf embeddedWAYF.js return URL
    displayMsg "INFO" "Adapt wayf embeddedWAYF.js return URL"
    debug=`sed -i "s#wayf_return_url = \".*\"#wayf_return_url = \"${baseURL}${RewriteBase}/?app=usv2\"#" ${output_folder}/wayf/js/embeddedWAYF.js 2>&1`
    manageError $? "${debug}" 0 1 "OK"

    # Modifier le template de la page de login
    if [[ -f "${output_folder}/themes/mycore/core/templates/login.php" ]]
    then
        displayMsg "INFO" "Adapting login template to ${RewriteBase}/"
        debug=`sed -i -e "s#/wayf/#${RewriteBase}/wayf/#" ${output_folder}/themes/mycore/core/templates/login.php 2>&1`
        manageError $? "${debug}" 0 1 "OK"
    fi
fi

# APPS config

# user_serverVars2 configuration, sso_url
displayMsg "INFO" "App user_servervars2, sso_url parameter"
debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ config:app:set usv2 sso_url --value="${baseURL}/Shibboleth.sso/Login?target=${baseURL}${RewriteBase}/?app=usv2"`
manageError $? "${debug}" 0 1 "OK"

# user_serverVars2 configuration, slo_url
displayMsg "INFO" "App user_servervars2, slo_url parameter"
debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ config:app:set usv2 slo_url --value="${baseURL}${RewriteBase}/exit.php?action=logout" 2>&1`

# gtu start_url parameter
displayMsg "INFO" "App gtu start_url, parameter"
debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ config:app:set gtu start_page_url --value="${baseURL}/${RewriteBase}/apps/files/" 2>&1`
manageError $? "${debug}" 0 1 "OK"

# password_policy faq parameter
displayMsg "INFO" "App password_policy, faq parameter (in config.php)"
debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ config:system:set "password_policy_faq" --value="${baseURL}${RewriteBase}/settings/personal" 2>&1`
manageError $? "${debug}" 0 1 "OK"

# user_account_action backup_file_dir parameter (in config.php)
displayMsg "INFO" "App user_account_action, backup_file_dir parameter (in config.php)"
debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ config:system:set "backup_file_dir" --value="${output_folder}/${RewriteBase}/data_backup" 2>&1`
manageError $? "${debug}" 0 1 "OK"

## TODO: manage_instance ligne 351 et suivantes (mail)

# Add email to admin user preferences
displayMsg "INFO" "Add email to admin user preferences"
debug=`${SUDO_BIN} -u ${apacheUID} ${PHP_BIN} ./occ user:setting --value="${ADMIN_EMAIL}" ${ADMIN_USER} settings email 2>&1`
manageError $? "${debug}" 0 1 "OK"

# Add or modify custom_adminemail in config.php
debug=`grep "custom_adminemail" "${output_folder}/config/config.php"`
if [[ $? -ge "1" ]]
then
    displayMsg "INFO" "Add admin email in config.php"
    debug=`sed -i -e "s#\(.*dbpassword.*\)#\1\n  'custom_adminemail' => '${ADMIN_EMAIL}',#" "${output_folder}/config/config.php" 2>&1`
    manageError $? "${debug}" 0 1 "OK"
else
    displayMsg "INFO" "Modify admin email in config.php"
    debug=`sed -i -e "s#'custom_adminemail' => .*#'custom_adminemail' => '${ADMIN_EMAIL}',#" "${output_folder}/config/config.php" 2>&1`
    manageError $? "${debug}" 0 1 "OK"
fi

# Add or modify monitoring_admin_email in config.php
debug=`grep "monitoring_admin_email" "${output_folder}/config/config.php"`
if [[ $? -ge "1" ]]
then
    displayMsg "INFO" "Add monitoring admin email in config.php"
    debug=`sed -i -e "s#\(.*dbpassword.*\)#\1\n  'monitoring_admin_email' => '${ADMIN_EMAIL}',#" "${output_folder}/config/config.php" 2>&1`
    manageError $? "${debug}" 0 1 "OK"
else
    displayMsg "INFO" "Modify monitoring admin email in config.php"
    debug=`sed -i -e "s#'monitoring_admin_email' => .*#'monitoring_admin_email' => '${ADMIN_EMAIL}',#" "${output_folder}/config/config.php" 2>&1`
    manageError $? "${debug}" 0 1 "OK"
fi

# ############ END SPECIFIC CNRS ###############