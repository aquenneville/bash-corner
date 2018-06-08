#!/bin/bash
usage() {
  echo "usage: $0 [new_cert_file: the new cert file] [new_cert_alias: the new alias]"
}

echo Script name: $0
if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    usage()
fi

new_cert_file=$1
new_cert_alias=$2

keytool -importcert -file ${new_cert_file} -alias ${new_cert_alias} -keystore cacerts
