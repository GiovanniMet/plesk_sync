#! /bin/sh

#
# @2016 Giovanni Metitieri
###########################

for domain in `mysql psa -u admin -p$(cat /etc/psa/.psa.shadow) -Ns -e 'select name from domains' | sort -u`; do
                domip=`/usr/local/psa/bin/domain --info $domain | grep address | cut -d\: -f2 | sed -e 's/^[ \t]*//'`;
                if [ $domip ]; then
                        echo "OK: $domain , $domip"
			/usr/local/psa/bin/dns --reset $domain -ip $domip
                fi
        done
