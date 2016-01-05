#!/bin/bash

line_to_domain_subdomain(){
        #create one line for each domain and subdomain
        echo "Generating entries..."
        echo "vi /etc/hosts" > lista_host
        for domain in `mysql psa -u admin -p$(cat /etc/psa/.psa.shadow) -Ns -e 'select name from domains' | sort -u`; do
                domip=`/usr/local/psa/bin/domain --info $domain | grep address | cut -d\: -f2 | sed -e 's/^[ \t]*//'`;
                if [ $domip ]; then
                        echo "$domip  $domain www.$domain" >> lista_host;
                fi
        done
        echo "Done!"
}

line_to_domain_subdomain
