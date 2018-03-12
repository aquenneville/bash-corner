#!bin/bash
usage() {
  echo "usage: $0 host_name certificate_name."  
}

$_HOST_NAME=$1
$_CERTIFICATE_NAME=$2

if [ "$#" -ne 2 ]; then
  usage()
fi

echo -n | openssl s_client -connect ${_HOST_NAME}:443 | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${_CERTIFICATE_NAME}
sudo cp ${_CERTIFICATE_NAME} /etc/ssl/certs
sudo dpkg-reconfigure ca-certificates
echo " $0"