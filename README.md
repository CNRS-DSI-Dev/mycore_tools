# My CoRe tools

Some bash scripts developed to facilitate My Core service management.
Current script provide the following functions :
* Show empty user groups (grp_null option of mycore_users.script script)
* Show local users, aka users created locally, without a shibolleth provisionning process (local_usr option of mycore_users.script script)
* Show unused users accounts (old_usr option of mycore_users.script script)
* Show users without default files quota (non_def_quota option of mycore_users.script script)
* Send to IT operational team email end users lists (list_usr option of mycore_users.script script)
* Delete user who have not been connected for an expiration number of days (del_old_usr option of mycore_users.script script)
* Show current migration requests, option in relation via user_files_migration app (list_migr option of mycore_users.script script)
* Add users to groups from a csv file (mycore_add_user_group.sh script)
* Add users as admin of groups from a csv file (mycore_add_admin_group.sh script)

## Usage

Syntax : 
usage: ./mycore_users.sh grp_null|local_usr|old_usr|non_def_quota|list_usr|list_migr
./mycore_add_user_group.sh <csv_file>
./mycore_add_admin_group.sh <csv_file>

Nota : list_migr list_migr needs https://github.com/CNRS-DSI-Dev/user_files_migrate installed and activated.

## Contributing

Theses tools are developed for an internal deployement of ownCloud at CNRS (French National Center for Scientific Research).

If you want to be informed about this ownCloud project at CNRS, please contact david.rousse@dsi.cnrs.fr, gilian.gambini@dsi.cnrs.fr or marc.dexet@dsi.cnrs.fr or jerome.jacques@ext.dsi.cnrs.fr

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Jérôme Jacques (<jerome.jacques@ext.dsi.cnrs.fr>)
| **Copyright:**       | Copyright (c) 2015 CNRS DSI
| **License:**         | AGPL v3, see the COPYING file.
