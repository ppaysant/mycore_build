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

## Contributing

This script is developed for an internal deployement of ownCloud at CNRS (French National Center for Scientific Research).

If you want to be informed about this ownCloud project at CNRS, please contact david.rousse@dsi.cnrs.fr, gilian.gambini@dsi.cnrs.fr or marc.dexet@dsi.cnrs.fr

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Gilian Gambini (<gilian.gambini@dsi.cnrs.fr>)
| **Copyright:**       | Copyright (c) 2015 CNRS DSI
| **License:**         | AGPL v3, see the COPYING file.
