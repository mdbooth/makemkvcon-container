#!/bin/bash

MAKEMKVDIR="${HOME}/.MakeMKV"
mkdir -p "${MAKEMKVDIR}"
echo "app_Key = \"${MAKEMKV_APP_KEY}\"" > "${HOME}/.MakeMKV/settings.conf"

exec /usr/bin/makemkvcon "$@"
