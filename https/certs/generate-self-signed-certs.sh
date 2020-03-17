#!/bin/bash
# This script generates SSL certs (.crt and .key) to be used with Apache/HAProxy/Nginx/etc.
# The files are generated in .PEM format (by default).

# Helpful info: 
# If the file's content begins with -----BEGIN and you can read it in a text editor,
#   then the file uses base64, which is readable in ASCII; thus not binary format. 
#   In this case, the certificate is already in PEM format. 
#   The server software can load such files without problems, 
#      irrespective of whatever the file extension may be.
#   You can change the extension to .pem - if you want to. (completey unnecessary)

echo

echo "Generating certificate files - ssl.key and ssl.crt - (PEM format) - valid for 10 years! :)"
echo "Executing: openssl req " \
                 "-x509 -newkey rsa:2048 -nodes -days 3650" \
                 "-keyout ssl.key -out ssl.crt -subj '/CN=localhost'"
echo

openssl req \
  -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout ssl.key -out ssl.crt -subj '/CN=localhost'

echo

echo "Combining the CRT and KEY files, into a combined (PEM) file."
echo "Executing: cat ssl.crt ssl.key > ssl-combined.pem"
echo
cat ssl.crt ssl.key > ssl-combined.pem
chmod 0600 ssl-combined.pem

echo "Generated files:"
ls -lh  ssl*.*
echo

