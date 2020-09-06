#!/bin/bash
[ -f "${1}" ] && {
  cat <<'__EOF__'
#!/bin/bash
[ "$BASH_SOURCE" = "${0}" ] || \
source <(cat "${BASH_SOURCE}" | tail -n+7 | cut -b2- \
       | base64 -di | gunzip -c) "${@}" \
       < <( [ -t 0 ] && echo "" || cat - );
__EOF__
  echo "## $( basename "${1}" ).gz.b64";
  cat "${1}" | gzip -c | base64 | sed -r 's/^/#/';
} > ${1}.gz.b64.sh;
