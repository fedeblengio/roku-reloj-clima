#!/bin/sh
# Empaqueta la app y, si se definen ROKU_IP y ROKU_PASS, la instala en la Roku.
#   ./build.sh
#   ROKU_IP=192.168.1.50 ROKU_PASS=tu_clave ./build.sh
set -e
cd "$(dirname "$0")"
rm -f reloj-clima.zip
zip -qr reloj-clima.zip manifest source components fonts images -x "images/CREDITOS.txt"
echo "Paquete: reloj-clima.zip"
if [ -n "$ROKU_IP" ] && [ -n "$ROKU_PASS" ]; then
  curl -s --digest -u "rokudev:$ROKU_PASS" -F "mysubmit=Install" -F "archive=@reloj-clima.zip" \
    "http://$ROKU_IP/plugin_install" | grep -oE '"text":"[^"]*"' | tail -1
fi
