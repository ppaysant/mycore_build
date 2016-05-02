# My CoRe build

A bash script to generate mycore tarball from various sources. 
Current supported repository :
* GitHub
* Subversion
* Apps.owncloud.com
* Local folder

A configuration file described which items to add.
Current item types :
* core
* app
* theme
* script

Script generate an output folder and a tarball. Tarball can use like official ownCloud release with your specifics.

## Usage

Syntax : ./mycore_build.sh \<my_conf\>.conf \<outputfolder\> \[{PRODUCTION|TEST}]\>

Actually, we recommand use only relative path. Last parameter is set by default to PRODUCTION : with TEST value, .svn and .git folders are not deleted in the outpup folder.

See https://github.com/CNRS-DSI-Dev/mycore_build/blob/master/INSTALL.md in order to configure ownCloud install packaged with this script.

## Deployement from a tgz file

Extract your tarball to your web root directory (ex: /var/www/)
Add those specification in the config/config.php file :
  'theme' => 'mycore',
  'appstoreenabled' => false,
  'custom_adminemail' => '<your admin email>',
  'knowledgebaseenabled' => false,
  'custom_knowledgebaseurl' => 'https://aide.core-cloud.net/mycore/Pages/Home.aspx',
  'custom_termsofserviceurl' => 'https://aide.core-cloud.net/mycore/Documents/myCoRe_CGU.pdf',
  'has_internet_connection' => false,
  'updatechecker' => false,
  'mail_from_address' => 'noreply',
  'mail_domain' => '<your mail domain>',
  'monitoring_admin_email' => '<your admin email>',
  'default_language' => 'fr',
  'enable_avatars' => false,
  'enable_previews' => false,
  'allow_user_to_change_display_name' => false,
  'activity_expire_days' => 30,
  'custom_ods_changelogurl' => 'https://aide.core-cloud.net/mycore/Documents/myCoRe_changelog.txt',
  'customclient_desktop' => 'http://owncloud.org/sync-clients/',
  'custom_ods_version' => '<version deployed>',
  'customclient_paid_windowsphone' => 'https://www.microsoft.com/fr-fr/store/apps/owncloud-client/9nblggh0fs2v',
  'migration_admin_email' => '<your admin email>',
  'migration_default_admin_email' => '<your default admin email>',
  'migration_default_exclusion_group' => '<your default exclusion group>',
  'migration_admin_emails' =>
  'password_policy_faq' => '/index.php/settings/personal#ppe',
  'custom_termsofserviceurl' => 'https://mycore.core-cloud.net/public.php?service=files&t=de4c1e65b9ed4f2b5f657c67d79e55fa',
  'help_url' => 'https://mycore.core-cloud.net/public.php?service=files&t=fe488d6e89e508e5cc0b5eaeef5fb7e8',
  'backup_file_before_user_deletion' => true,
  'backup_file_dir' => '<your backup file directory>',
  ),

=== Additionnal seetings ===
= Enable apps =
= Share seetings =

Allow users to send an email to notify file/directory sharing : enable

= File management =

Allow file 4096MB file upload in php.ini file

= Antivirus =

Add Index on table oc_files_antivirus:
ALTER TABLE `oc_files_antivirus` ADD INDEX ( `fileid` ) ; 

Mode : Deamon (socket)
Socket : /var/run/clamav/clamd.sock (can be found in /etc/clamd.conf)
Stream length : 10485760
Action : Only notify

= Password policy =

Minimum length : 8
Need Upper and Lower character : enable
Need Numbers : enable
Need special character : enable
Special character list : @?!&-_()=

= user_servervars2 =

In the webUI, admin panel:
Stop If Empty : enable



## Contributing

This script is developed for an internal deployement of ownCloud at CNRS (French National Center for Scientific Research).

If you want to be informed about this ownCloud project at CNRS, please contact david.rousse@dsi.cnrs.fr, gilian.gambini@dsi.cnrs.fr or marc.dexet@dsi.cnrs.fr

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Gilian Gambini (<gilian.gambini@dsi.cnrs.fr>)
| **Copyright:**       | Copyright (c) 2015 CNRS DSI
| **License:**         | AGPL v3, see the COPYING file.
