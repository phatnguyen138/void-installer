#!/bin/bash
i="$(xbps-install -Mun 2>/dev/null)"
printf "%b%b" "$i" "${i:+\n}" |wc -l; echo "$i" |column -t
