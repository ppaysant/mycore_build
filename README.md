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

Syntax : ./mycore_build.sh \<my_conf\>.conf \<outputfolder\>

Actually, we recommand use only relative path. 

## Configuration examples




## Contributing

This script is developed for an internal deployement of ownCloud at CNRS (French National Center for Scientific Research).

If you want to be informed about this ownCloud project at CNRS, please contact david.rousse@dsi.cnrs.fr, gilian.gambini@dsi.cnrs.fr or marc.dexet@dsi.cnrs.fr

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Gilian Gambini (<gilian.gambini@dsi.cnrs.fr>)
| **Copyright:**       | Copyright (c) 2014 CNRS DSI
| **License:**         | AGPL v3, see the COPYING file.
