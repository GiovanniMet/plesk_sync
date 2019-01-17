#!/bin/sh

dump_root='/root/mydumper'
tread=8

settings(){
#in case of error edit here and run with screen!
    TARGET_USER=root
    TARGET=123.123.123.123
    TARGET_PORT=22
    LOG_FILE=migrationlog.log
}

dump_mysql() {
  local my_user="admin"
  local my_pwd="$(cat /etc/psa/.psa.shadow)"

  [ -d $dump_root ] || mkdir -p $dump_root
  cd $dump_root

  if [ -t 0 ]; then
    echo "Dumping in $dump_root"
  fi

  mydumper --regex '^(?!(apsc|sitebuilder5|psa|mysql|horde|information_schema|performance_schema|phpmyadmin.*))' \
    --socket /run/mysqld/mysqld.sock \
    --user "$my_user" --password "$my_pwd" \
    --build-empty-files --compress \
    --trx-consistency-only \
    --triggers --events \
    --routines --rows=100000 \
    --threads $tread --compress-protocol
}

dbsyncscript () {
    ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "screen -S dbsync -d -m bash /root/restore_faster.sh"
    echo "Databases are importing in a screen on the target server. Be sure to check there to make sure they all imported OK."
    sleep 2
}

sync_database() {
    #perform just a database sync, reimporting on the target side.
    echo "Dumping the databases..."
    #run mydumper to a faster dump
    dump_mysql
    #move the dumps to the new server
    rsync -avHlPze "ssh -q -p$TARGET_PORT" $dump_root $TARGET_USER@$TARGET:/var/
    #start import of databases in screen on target
    dbsyncscript
    rm -rf $dump_root
}

sync(){
    sync_database
}

#MAIN
main(){
    settings
    sync
}

main
