#!/bin/bash
#########################################################################
# mui.sh - select "M"enu "UI" script for bash
#  Author : hfftjp
#  Usage :
#   [1] ls -1 / | . ./mui.sh | paste -sd,
#   [2] . ./mui.sh; __mui_start -v__var < <(ls -1 /); echo "${__var}";
#########################################################################
## start UI
function __mui_start(){
  [ -t 0 ] && return 11; ## no list
  
  # local variables; get parent variables' name;
  local __mui_varsl __mui_selval __mui_vartp __mui_toppos __mui_exitcd \
    __mui_inlist="$(cat -)";
  [ -z "${__mui_inlist}" ] && return 11;
  __mui_varsl="$(
    echo "${@}" | sed -rn "s/^(|.*\s)\-v\s*(\S+)(\s.*|)$/\2/p")";
  __mui_vartp="$(
    echo "${@}" | sed -rn "s/^(|.*\s)\-p\s*(\S+)(\s.*|)$/\2/p")";
  [[ "${__mui_varsl:-x}" =~ ^[_a-zA-Z][-_0-9a-zA-Z]*$ ]] || return 12;
  [[ "${__mui_vartp:-x}" =~ ^[_a-zA-Z][-_0-9a-zA-Z]*$ ]] || return 13;
  __mui_toppos="${!__mui_vartp}";
  
  # initialize UI ( save stdout; hide cursor; input feedback off; )
  exec 3>&1- 1>/dev/tty; tput civis; stty -F /dev/tty -echo;
  [ ${BASH_VERSINFO[0]:-3} -le 3 ] \
    && stty -F /dev/tty -icanon time 0 min 0;
  
  # call main
  __mui_main "${@}" < <(echo "${__mui_inlist}"); __mui_exitcd=$?;
  
  # finalize UI
  __mui_end; exec 1>&3-;
  [ ${__mui_exitcd:=255} -eq 0 ] || return ${__mui_exitcd};
  
  ## return cursor position / selected values
  [ -n "${__mui_vartp}" ] && eval "${__mui_vartp}=\"${__mui_toppos}\"";
  [ -z "${__mui_varsl}" ] && echo "${__mui_selval}" || \
    eval "${__mui_varsl}=\"$( \
    echo -n "${__mui_selval}" | sed -r -e 's/(["`$\])/\\\1/g'; )\""; #'
  
  return 0;
}

## cleanup IF / functions
function __mui_end(){
  tput cnorm; stty -F /dev/tty echo;
  [ ${BASH_VERSINFO[0]:-3} -le 3 ] \
    && stty -F /dev/tty icanon time 0 min 1;
}
function __mui_unload(){
  __mui_end; unset $(set | grep -Eo "^__mui_[^= ]+"| paste -s);
}

## main
function __mui_main(){
  # local variables
  local -r __M_HBAR="$(printf '%.0s=' {1..500})" __M_AR='=>' 2>/dev/null;
  local -r __M_MENU_TITLE='menu' __M_SP="${__M_HBAR//?/ }"     \
    __C_H="\x1b[1;34m"; __C_0="\x1b[0m" __C_S="\x1b[47m"       \
    __K_ESC=$'\x1b' __K_BS=$'\x08' __K_DEL=$'\x7f'             \
    __K_LF=$'\x0a'  __K_SP=$'\x20'                             \
    __K_UP=$'\x1b\x5b\x41'       __K_DOWN=$'\x1b\x5b\x42'      \
    __K_RIGHT=$'\x1b\x5b\x43'    __K_LEFT=$'\x1b\x5b\x44'      \
    __K_HOME=$'\x1b\x5b\x31\x7e' __K_END=$'\x1b\x5b\x34\x7e'   \
    __K_PGUP=$'\x1b\x5b\x35\x7e' __K_PGDOWN=$'\x1b\x5b\x36\x7e'\
    __K_CTL_A=$'\x01' __K_CTL_R=$'\x12' __K_CTL_V=$'\x16'      \
    2>/dev/null;
  local __list __lim=99 __ldgt=2 __select __multi=99 __numsel=0        \
    __top=1 __pos=1 __min=1 __max __rows __mrkin __lmrkin __buf        \
    __ind="" __indl __inds __len=1 __hlen=2 __title="${__M_MENU_TITLE}"\
    __drow=$(($(tput lines)-2)) __dlen=$(($(tput cols)-1)) __footer    \
    __ar="${__M_AR}" __ars __wid=0 __wid_min __wid_if                  ;
  
  ### for body ( top/pos )
  [[ "${__mui_toppos}" =~ ^[1-9][0-9]*:[1-9][0-9]*$ ]] \
    && { __top="${__mui_toppos%:*}"; __pos="${__mui_toppos#*:}"; };
  
  ## read / check stdin
  __list="$(cat - | grep -vE "^\s*$" | head -${__lim} \
              | awk '{printf "%0'"${__ldgt}"'d:%s\n",NR,$0}')";
  __max=$(__mui_lncnt "${__list}"); [ ${__max} -ge 1 ] || return 11;
  __rows=${__max};
  
  ## read args.
  while [ -n "${1}" ]; do
    case "${1}" in
      -v* ) __mui_opt __buf    "${@}" && shift;;
      -p* ) __mui_opt __buf    "${@}" && shift;;
      -m* ) __mui_opt __multi  "${@}" && shift;;
      -s  ) __mui_opt __multi  "${1}" 1       ;;
      -t* ) __mui_opt __title  "${@}" && shift;;
      -r* ) __mui_opt __rows   "${@}" && shift;;
      -i* ) __mui_opt __ind    "${@}" && shift;;
      -n  ) __mui_opt __numsel "${1}" 1       ;;
      -w* ) __mui_opt __wid    "${@}" && shift;;
      -A  ) __mui_opt __ar     "${1}" ''      ;;
      *   ) return 10;;
    esac;
    shift;
  done;
  __buf="";
  
  ## check args.
  [[ "${__multi}" =~ ^[1-9][0-9]{0,$((__ldgt-1))}$ ]] || return 14;
  [[ "${__ind}"   =~ ^[0-9]*$ ]]                      || return 15;
  [[ "${__rows}"  =~ ^[1-9][0-9]*$ ]]                 || return 16;
  [[ "${__wid}"   =~ ^[0-9]*$ ]]                      || return 17;
  __indl=${__ind:-0}; [ -z "${__ind}" ] && __inds="\x1b[K\r" || \
  { [ ${__ind} -eq 0 ] && __ind="\r" || __ind="\r\x1b[${__ind}C";
    __inds="\r"; };
  __ars="${__M_SP:0:$(__mui_wlen "${__ar}")}";
  (( __multi>__lim && ( __multi=__lim )
    ,__rows>__drow && ( __rows=__drow )
    ,__rows>__max  && ( __rows=__max )
    ,__wid_min = (__multi>1?2:0)+$(__mui_wlen "${__ar}")+1
    ,__wid_min < ((__max>__rows?3:0)+(__multi>1?(__ldgt+1):0)) && \
       ( __wid_min = (__max>__rows?3:0)+(__multi>1?(__ldgt+1):0))
    ,__wid_if = (__max>__rows?(__ldgt*2+1):0)+(__multi>1?(__ldgt+3):0)
    ,__wid_if = __wid_if+(__wid_if>0?2:0)+__hlen*2
    ,__wid_if < __wid_min && ( __wid_if = __wid_min ) ));
  
  ## set title/footer text
  [ ${#__title} -ne 0 ] && __title=" ${__title} ";
  __footer="$(
    [ ${__max} -eq ${__rows} ] || echo -n "${__lim//9/a}/${__lim//9/b}";
    [ ${__multi} -eq 1 ] || echo -n '(*'${__lim//9/c}')'; )";
  [ ${#__footer} -ne 0 ] && __footer=" ${__footer} ";
  
  ## calc length
  (( __len = $(__mui_wlen "${__list}")-(__ldgt+1) \
               +(__multi>1?2:0)+$(__mui_wlen "${__ar}")
   , __len < $(__mui_wlen "${__footer}")+__hlen*2 \
       && ( __len = $(__mui_wlen "${__footer}")+__hlen*2 )
   , __len < $(__mui_wlen "${__title}")+__hlen*2 \
       && ( __len = $(__mui_wlen "${__title}")+__hlen*2 )
   , __wid>=__wid_min && (__len=__wid)
   , __len>(__dlen-__indl) && (__len=__dlen-__indl) ));
  
  __mui_display_function_update;
  __title="$( __mui_fill_hbar "${__title}" 0 )";
  [ ${__len} -lt ${__wid_if} ] && __footer="$( __mui_fill_hbar "$(
    [ ${__max} -eq ${__rows} ] || echo -n 'd-e';
    [ ${__multi} -eq 1 ] || echo -n '*'${__lim//9/c}; )" 1 0 )" \
    || __footer="$( __mui_fill_hbar "${__footer}" 1 )";
  
  ## user input loop / update display UI
  __mui_display 1; # Initial display UI
  while [ -n "${__mrkin}" ] && __mui_display; __mui_readkey; do
    
    ## move / select / quit
    case "${__mrkin}" in
      "k" | "${__K_UP}"   ) (( __pos-- ));;
      "j" | "${__K_DOWN}" ) (( __pos++ ));;
      "h" | "${__K_LEFT}"  | "${__K_PGUP}" )
          (( __pos-=__rows ,__top-=__rows ));;
      "l" | "${__K_RIGHT}" | "${__K_PGDOWN}" )
          (( __pos+=__rows ,__top+=__rows ));;
      "${__K_HOME}" ) __pos=${__min};;
      "${__K_END}"  ) __pos=${__max};;
      "${__K_SP}" ) __mui_upd_selected;;
      "${__K_LF}" ) [ ${__multi} -eq 1 ] && __select="$(__mui_pos_val)";
                    break;;
      "q" | "Q" | "${__K_ESC}" | "${__K_BS}" | "${__K_DEL}" )
        __select=""; break;;
    esac;
    
    ## move and select, all/none/invert (__multi > 1)
    [ ${__multi} -gt 1 ] && \
    case "${__mrkin}" in
      "K" ) if ! [ ${__pos} -le ${__min} ]; then
              [ "${__lmrkin}" != "${__mrkin}" ] && __mui_upd_selected;
              (( __pos-- )); __mui_upd_selected;
            fi;;
      "J" ) if ! [ ${__pos} -ge ${__max} ]; then
              [ "${__lmrkin}" != "${__mrkin}" ] && __mui_upd_selected;
              (( __pos++ )); __mui_upd_selected;
            fi;;
      "a" | "${__K_CTL_A}" )
            [ ${__max} -le ${__multi} ] && __select="${__list}";;
      "r" | "${__K_CTL_R}" ) __select="";;
      "i" | "${__K_CTL_V}" )
            [ $(( __max-$(__mui_lncnt "${__select}") )) -le ${__multi} ]\
              && __select="$(echo "${__list}"$'\n'"${__select}" \
                             | grep -vE "^\s*$" | sort | uniq -u )";;
    esac;
    
    ## jump to menu number (__numsel == 1)
    [ ${__numsel} -eq 1 ] && \
    case "${__mrkin}" in
      [0-9] )
        __buf="$(echo "${__list}"$'\n'"${__list}" \
          | sed -rn "$((__pos+1)),$((__pos+__max)){ \
             s/^[0-9]{${__ldgt}}:(.*)$/\1/; /^\s*${__mrkin}/=; }")";
        if [ -n "${__buf}" ]; then
          (( __pos=($(echo "${__buf}" | head -1)-1)%__max+1 ));
          if [ $(__mui_lncnt "${__buf}") -eq 1 ] \
               && [ ${__multi} -eq 1 ]; then
            __mui_display;
            __select="$(__mui_pos_val)";
            break;
          fi;
        fi;;
    esac;
    
    ## for single selection (__multi == 1)
    [ ${__multi} -eq 1 ] && [ $(__mui_lncnt "${__select}") -eq 1 ] \
      && break;
    
  done;
  
  echo ""; # print "\n" instead of traped by __mui_readkey
  
  ## return cursor position
  __mui_toppos="${__top}:${__pos}";
  
  ## return selected values
  __mui_selval="$(echo "${__select}" \
    | sed -r 's/^[0-9]{'"${__ldgt}"'}://')";
  
  return 0;
}

## title/footer coloring and padding with hbar
function __mui_fill_hbar(){
  local __r __l __h=${3:-${__hlen}} __tlen=$(__mui_wlen "${1}");
  (( ${2:-0} == 0 ? ( __l=__h ,__r=__len-__tlen-__l ) \
                  : ( __r=__h ,__l=__len-__tlen-__r ) 
    ,__len < __tlen && ( __l=0 ,__r=0 ) ));
  echo -n "${__M_HBAR:0:${__l}}${1}${__M_HBAR:0:${__r}}";
}

## read args.
function __mui_opt(){
  [ -z "${2}" ] && return 1;
  [ -n "${2:2}" ] && eval "${1}=\"${2:2}\"" && return 1;
  [ "${3:0:1}" = "-" ] && eval "${1}=''" && return 1;
  eval "${1}=\"${3}\"" && return 0;
}

## get value on cursor position
function __mui_pos_val(){
  (( __pos>__max && ( __pos=__max ) ,__pos<__min && ( __pos=__min ) ));
  echo "${__list}" | sed -n "${__pos}p";
}

## update selected values list
function __mui_upd_selected(){
  local __tmp="$(echo "${__select}"$'\n'"$(__mui_pos_val)" \
    | grep -vE "^\s*$" | sort | uniq -u)";
  [ $(__mui_lncnt "${__tmp}") -le ${__multi} ] && __select="${__tmp}";
}

## display title, body & footer ( arg[1]= 0:update, 1:init )
function __mui_display(){
  # fix pos
  (( __pos>__max && ( __pos=__max ) ,__pos<__min && ( __pos=__min )
   , __top>(__max-__rows+1) && ( __top=__max-__rows+1 )
   , __top<__min && ( __top=__min ) ,__top>__pos && ( __top=__pos )
   , __top<(__pos-__rows+1) && ( __top=__pos-__rows+1 ) ));
  
  # title & footer
  local __tmpt="${__ind}${__C_H}${__title:0:${__len}}${__C_0}${__inds}"\
        __tmpf="${__footer}";
  __mui_display_gen_footer;
  __tmpf="$(echo -n "${__tmpf}" | sed -r \
    "s|c+|$(printf "%${__ldgt}d" $(__mui_lncnt "${__select}"))|")";
  __tmpf="${__ind}${__C_H}${__tmpf:0:${__len}}${__C_0}${__inds}";
  
  # display
  __mui_display_gen_body \
    | awk -v upd=${1:-0} -v rows=$((__rows+1)) -v ind="${__ind}" \
      -v inds="${__inds}" -v title="${__tmpt}" -v footer="${__tmpf}" \
      'BEGIN{ if(upd==0) printf "\x1b["rows"A\r"; print title; };
       { print; }; END{ printf "\r%s",footer; };';
}
function __mui_display_function_update(){
# __mui_display_gen_footer
if [ ${__len} -lt ${__wid_if} ]; then
  function __mui_display_gen_footer(){
    [ ${__max} -gt $(( __top-1+__rows )) ] && __tmpf="${__tmpf//e/>}";
    [ ${__min} -lt ${__top} ] && __tmpf="${__tmpf//d/<}";
    __tmpf="${__tmpf//[de]/-}";
  };
else
  function __mui_display_gen_footer(){
    __tmpf="$(echo -n "${__tmpf}" | sed -r \
      "s|a+/b+|$(printf "%${__ldgt}d/%${__ldgt}d" ${__pos} ${__max})|")";
  };
fi;
# __mui_display_gen_body
if [ ${__multi} -eq 1 ]; then
  function __mui_display_gen_body(){
  echo "${__list}" \
    | sed -rn "${__top},$((__top+__rows-1)){ \
        s/\t/ /g;s/^[0-9]{${__ldgt}}:(.*)$/${__ars}\1${__M_SP}/;p; }" \
    | pr -t -W${__len} \
    | sed -r "$((__pos-__top+1)) \
        s/^${__ars}(.*)$/${__ar}${__C_S}\1${__C_0}/;\
        s/^(.*)$/${__ind}\1${__inds}/;";
  };
else
  function __mui_display_gen_body(){
  join -t $'\v' -a 1 -1 1 -2 2 -o 2.1 1.1 -e ' ' \
    <(echo "${__list}" | sed -n "${__top},$((__top+__rows-1))p") \
    <(echo "${__select}" | sed -r "s/^/*\v/") \
    | sed -r "s/\t/ /g;\
        s/^(.)\v[0-9]{${__ldgt}}:(.*)$/${__ars}\1 \2${__M_SP}/" \
    | pr -t -W${__len} \
    | sed -r "$((__pos-__top+1)) \
        s/^${__ars}(..)(.*)$/${__ar}\1${__C_S}\2${__C_0}/;
        s/^(.*)$/${__ind}\1${__inds}/" ;
  };
fi;
}

## key input to __mrkin/__lmrkin
function __mui_readkey(){
  local __mrkbuf; __lmrkin="${__mrkin}";
  IFS= read -rsn1 -d $'\x00' __mrkin </dev/tty || return 1; # get 1byte
  case "${__mrkin}" in [$'\x20'-$'\x7e'] ) return 0;; esac; # 1byte
  if [ "${__mrkin}" = $'\x1b' ]; then # for [ESC](0x1b) + xxx
    while __mui_getkey; do
      [ -z "${__mrkbuf}" ] || [ "${__mrkbuf}" = $'\x1b' ] && break; # ESC
      __mrkin="${__mrkin}${__mrkbuf}";
      [ "${__mrkin:0:2}" = $'\x1b\x5b' ] || break; # not ESC + '['
      [ ${#__mrkin} -ge 5 ] && break; # len=5 (max) F1-F12
      [ "${__mrkbuf}" = $'\x7e' ] && break; # detect '~' for len=4
      case "${__mrkin}" in
        $'\x1b\x5b\x41' | $'\x1b\x5b\x42' | \
        $'\x1b\x5b\x43' | $'\x1b\x5b\x44' ) break;;
      esac;
    done;
  fi;
  return 0;
}
if [ ${BASH_VERSINFO[0]:-3} -le 3 ]; then
  function __mui_getkey(){
    __mrkbuf=$(head -c1 </dev/tty); [ -n "${__mrkbuf}" ];
  }
else
  function __mui_getkey(){
    IFS= read -rsn1 -t 0.01 -d $'\x00' __mrkbuf </dev/tty;
  }
fi;

## line count
function __mui_lncnt(){ echo -n "${1}" | awk 'END{print NR}'; }

## get max line length
function __mui_wlen(){
  echo $(( $( echo $'\n'"${1}"$'\n' | sed -r 's/\t/ /g;s/.*/x&\vx/;' \
      | column -t -s$'\v' | head -1 | wc -c ) - 5 ));
}
#########################################################################
## call __mui_start
[ "$BASH_SOURCE" = "${0}" ] && exit 255; # for source call only
[ -t 0 ] || __mui_start "${@}" < <(cat -) || ( __cd=$?; \
  echo -e "\x1b[1;31mERROR:(${__cd})\x1b[0m" >&2; exit ${__cd} );
