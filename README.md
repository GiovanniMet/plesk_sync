Plesk Initial Sync
==================

Migration and sync script for plesk to plesk migrations, written in bash. 
Use plesk CMD command to do all in a easy way.

Requirements
------------
Source server requires Debian, RHEL 4+ or equivalent with Plesk, and mysql for database storage.

Target server requires Debian, RHEL 4+ (preferably 6) or equivalent with Plesk 12.5 or greater and mysql for database storage. Will require passworded root SSH login on any port, and screen to be installed. 

The servers should have increasing versions of Plesk. That is, the target server's Plesk version should be greater than or equal to the source's version. Migrating from 12.5 to 12.0, for instance, will fail.

Instruction
------------
1. Download and execute run_me.sh
2. Edit run_me.sh for target server
3. Enjoy! It automatically download and execute lastest script version.
