#!/bin/bash
#########################################################################
# lmui.sh - select "M"enu "UI" script for bash ( lite )
#  Author : hfftjp
#  Usage :
#   [1] ls -1 / | . lmui.sh | paste -sd,
#   [2] . lmui.sh; __mui_start -v__var < <(ls -1 /); echo "${__var}";
#########################################################################
## start UI
function __mui_start(){
  [ -t 0 ] && return 11; ## no list
  local __mui_inlist="$(cat -)"; [ -z "${__mui_inlist}" ] && return 11;
  
  # local variables; get parent variables' name;
  local __mui_varsl __mui_selval __mui_vartp __mui_toppos __mui_exitcd;
  __mui_opts v __mui_varsl name "${@}" || return 12;
  __mui_opts p __mui_vartp name "${@}" || return 13;
  __mui_toppos="${!__mui_vartp}";
  __mui_selval="${!__mui_varsl}";
  
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
  local -r __M_SP="$(printf '%.0s ' {1..300})" __M_AR='>' __M_SL='*' \
    __C_0="\x1b[0m" __C_S="\x1b[47m" __C_B="\x1b[1;34m" \
    __K_ESC=$'\x1b' __K_BS=$'\x08' __K_DEL=$'\x7f' \
    __K_LF=$'\x0a' __K_SP=$'\x20' \
    __K_CTL_A=$'\x01' __K_CTL_R=$'\x12' \
    __K_CTL_V=$'\x16' __K_CTL_N=$'\x0e' \
    __K_UP=$'\x1b\x5b\x41'       __K_DOWN=$'\x1b\x5b\x42'       \
    __K_RIGHT=$'\x1b\x5b\x43'    __K_LEFT=$'\x1b\x5b\x44'       \
    __K_HOME=$'\x1b\x5b\x31\x7e' __K_END=$'\x1b\x5b\x34\x7e'    \
    __K_PGUP=$'\x1b\x5b\x35\x7e' __K_PGDOWN=$'\x1b\x5b\x36\x7e' \
    2>/dev/null;
  local __list __lim=99 __ldgt=2 __select __multi=99 __numsel=0 \
    __top=1 __pos=1 __min=1 __max __rows __mrkin __lmrkin __buf \
    __ind="" __indl __inds="" __len=1 __wid=0 __wid_min         \
    __drow=$(($(tput lines)-2)) __dlen=$(($(tput cols)-1))      \
    __ar="${__M_AR}" __ars __arl __scl=1;
  
  ### for body ( top/pos )
  [[ "${__mui_toppos}" =~ ^[1-9][0-9]*:[1-9][0-9]*$ ]] \
    && { __top="${__mui_toppos%:*}"; __pos="${__mui_toppos#*:}"; };
  
  ## read / check stdin
  __list="$( cat - | grep -vE "^\s*$" | head -${__lim} \
              | awk '{printf "%0'"${__ldgt}"'d:%s\n",NR,$0}')";
  __max=$(__mui_lncnt "${__list}"); [ ${__max} -ge 1 ] || return 11;
  __rows=${__max};
  [ ${__multi} -ne 1 ] && __select="$( \
    join -1 1 -2 2 -t $'\v' -o 2.1,2.2 \
    <( echo "${__mui_selval}" | sort | uniq ) \
    <( echo "${__list}" | sed -r "s/^([0-9]{${__ldgt}}):(.*)$/\1\v\2/" \
    | sort -t $'\v' -k 2 ) | tr $'\v' ':' )";
  
  ## read/check args.
  __mui_opts m __multi  ldgt "${@}" || return 14;
  __mui_opts s __multi  =1   "${@}";
  __mui_opts r __rows   uint "${@}" || return 16;
  __mui_opts i __ind    int  "${@}" || return 15;
  __mui_opts n __numsel =1   "${@}";
  __mui_opts w __wid    int  "${@}" || return 17;
  __mui_opts A __ar     =    "${@}";
  __mui_opts S __scl    =0   "${@}";
  [ $(__mui_lncnt "${__select}") -le ${__multi} ] || return 18;
  __indl=${__ind:-0}; [ -z "${__ind}" ] && __inds="\x1b[0K" || \
  { [ ${__ind} -eq 0 ] && __ind="" || __ind="\x1b[${__ind}G"; };
  __arl=$(__mui_wlen "${__ar}"); __ars="${__M_SP:0:${__arl}}";
  (( __multi>__lim && ( __multi=__lim )
    ,__rows>__drow && ( __rows=__drow )
    ,__rows>__max  && ( __rows=__max )
    ,__max==__rows && ( __scl=0 )
    ,__wid_min = (__multi>1?1:0)+__arl+1+__scl ));
  ## calc length
  (( __len = $(__mui_wlen "${__list}")-(__ldgt+1)+(__multi>1?1:0)+__arl
   , __wid>=__wid_min && (__len=__wid-__scl)
   , __len>(__dlen-__indl-__scl) && (__len=__dlen-__indl-__scl) ));
  __mui_display_function_update;
  
  ## user input loop / update display UI
  __mui_display 1; # Initial display UI
  while [ -n "${__mrkin}" ] && __mui_display; __mui_readkey; do
    
    ## move / select / quit
    case "${__mrkin}" in
      [kw] | "${__K_UP}"   ) (( __pos-- ));;
      [js] | "${__K_DOWN}" ) (( __pos++ ));;
      [ha] | "${__K_LEFT}"  | "${__K_PGUP}"   )
        (( __pos-=__rows ,__top-=__rows ));;
      [ld] | "${__K_RIGHT}" | "${__K_PGDOWN}" )
        (( __pos+=__rows ,__top+=__rows ));;
      "${__K_HOME}" ) __pos=${__min};;
      "${__K_END}"  ) __pos=${__max};;
      "${__K_SP}" ) __mui_upd_selected;;
      "${__K_LF}" ) [ ${__multi} -eq 1 ] && __select="$(__mui_pos_val)";
        break;;
      [qQ] | "${__K_ESC}" | "${__K_BS}" | "${__K_DEL}" )
        __select=""; break;;
    esac;
    
    ## move and select, all/none/invert (__multi > 1)
    [ ${__multi} -gt 1 ] && \
    case "${__mrkin}" in
      [KW] ) if ! [ ${__pos} -le ${__min} ]; then
               [ "${__lmrkin}" != "${__mrkin}" ] && __mui_upd_selected;
               (( __pos-- )); __mui_upd_selected;
             fi;;
      [JS] ) if ! [ ${__pos} -ge ${__max} ]; then
               [ "${__lmrkin}" != "${__mrkin}" ] && __mui_upd_selected;
               (( __pos++ )); __mui_upd_selected;
             fi;;
      "${__K_CTL_A}" )
        [ ${__max} -le ${__multi} ] && __select="${__list}";;
      "${__K_CTL_R}" | "${__K_CTL_N}" ) __select="";;
      "${__K_CTL_V}" )
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
            __mui_display; __select="$(__mui_pos_val)"; break;
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

## read args. [1]:opt, [2]:varname, [3]:check, [4]:args(original)
function __mui_opts(){
  echo "${@:4}" | grep -Eq "^([-:]|.*\s-|.*:)${1}" || return 0;
  [ "${3:0:1}" = "=" ] && eval "${2}=\"${3:1}\"" || \
  eval "${2}=\"$(echo "${@:4}" \
    | sed -rn "s/^([-:]|.*\s-|.*:)${1}\s*([^: ]+)(:.*|\s.*|)$/\2/p")\"";
  case "${3}" in
    "name" ) eval "[[ \"\${${2}:-x}\" =~ ^[_a-zA-Z][-_0-9a-zA-Z]*$ ]]";;
    "ldgt" ) eval "[[ \"\${${2}}\" =~ ^[1-9][0-9]{0,$((__ldgt-1))}$ ]]";;
    "uint" ) eval "[[ \"\${${2}}\" =~ ^[1-9][0-9]*$ ]]";;
    "int"  ) eval "[[ \"\${${2}}\" =~ ^[0-9]*$ ]]";;
    *      ) return 0;;
  esac;
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
  
  # display
  __mui_display_gen_body \
    | awk -v upd=${1:-0} -v rows=$((__rows-1)) \
      'BEGIN{ if(upd==0 && rows>0) printf "\x1b["rows"F"; };
       NR==1{ printf("%s",$0); }; NR>1{ printf("\n%s",$0); };';
}
function __mui_display_function_update(){
# __mui_display_gen_body
if [ ${__multi} -eq 1 ]; then
  function __mui_display_gen_body(){
  echo "${__list}" \
    | sed -rn "${__top},$((__top+__rows-1)){ \
        s/\t/ /g;s/^[0-9]{${__ldgt}}:(.*)$/${__ars}\1${__M_SP}/;p; }" \
    | pr -t -W${__len} | __mui_display_scroll_bar \
    | sed -r "$((__pos-__top+1)) \
        s/^${__ars}(.*)(.{${__scl}})$/${__ar}${__C_S}\1${__C_0}\2/;\
        s/^(.{${__arl}})/${__C_B}\1${__C_0}/;
        s/^(.*)(.{${__scl}})$/${__ind}\1${__C_B}\2${__C_0}${__inds}/;" ;
  };
else
  function __mui_display_gen_body(){
  join -t $'\v' -a 1 -1 1 -2 2 -o 2.1 1.1 -e ' ' \
    <(echo "${__list}" | sed -n "${__top},$((__top+__rows-1))p") \
    <(echo "${__select}" | sed -r "s/^/${__M_SL}\v/") \
    | sed -r "s/\t/ /g;\
        s/^(.)\v[0-9]{${__ldgt}}:(.*)$/${__ars}\1\2${__M_SP}/" \
    | pr -t -W${__len} | __mui_display_scroll_bar \
    | sed -r "$((__pos-__top+1))\
        s/^${__ars}(.)(.*)(.{${__scl}})$/${__ar}\1${__C_S}\2${__C_0}\3/;
        s/^(.{${__arl}}.)/${__C_B}\1${__C_0}/;
        s/^(.*)(.{${__scl}})$/${__ind}\1${__C_B}\2${__C_0}${__inds}/;" ;
  };
fi;

}
function __mui_display_scroll_bar(){
   [ ${__scl} -eq 0 ] && cat - || \
   cat - | awk -v min=${__min} -v max=${__max} \
               -v top=${__top} -v rows=${__rows} '
   { printf "%s",$0; }
   NR==1 && rows!=1 { if(min < top)printf "<"; else printf "-"; }
   NR>1 && NR<rows {
     if ( int(top*(rows-2)/max) <= (NR-1) \
        && (NR-1) <=int((top+rows-1)*(rows-2)/max+0.9) \
        && max>rows ){ printf "+"; } else { printf "|"; }; }
   NR==rows {
     if((top+rows-1) < max) printf ">"; else {
        if(rows!=1)printf "-"; else {
          if(min < top)printf "<"; else printf "-"; }}; }
   { printf "\n"; }
   ';
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
