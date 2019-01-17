#!/bin/sh

dump_root='/var/mydumper/'
tread=8

dump_root=$(find $dump_root/* -type d)

restore_mysql() {
  local my_user="admin"
  local my_pwd="$(cat /etc/psa/.psa.shadow)"

  data=$(date)
  echo $data "Inizio " >> restore-mysql.log

  myloader \
  --socket /run/mysqld/mysqld.sock \
  --user "$my_user" --password "$my_pwd" \
  --directory=$dump_root \
  --queries-per-transaction=50000 \
  --threads=$tread \
  --compress-protocol \
  --overwrite-tables

  data=$(date)
  echo $data "Fine " >> restore-mysql.log
}

restore_mysql
rm -rf $dump_root
