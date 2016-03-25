
#!/bin/bash

main(){
        #create one line for each domain and subdomain
        echo "Generating entries..."
        echo "#!/bin/bash" > update_ip.sh
        for domain in `mysql psa -u admin -p$(cat /etc/psa/.psa.shadow) -Ns -e 'select name from domains' | sort -u`; do
                domip=`/usr/local/psa/bin/domain --info $domain | grep address | cut -d\: -f2 | sed -e 's/^[ \t]*//'`;
                if [ $domip ]; then
                        echo "/usr/local/psa/bin/domain --update $domain -ip$domip" >> update_ip.sh;
                fi
        done
        echo "Done!"
}

main
