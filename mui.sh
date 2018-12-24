#!/bin/bash
#########################################################################
# mui.sh - select "M"enu "UI" script for bash
#
# Example of use :
#     [1] ls -1 / | ./mui.sh | grep -En '';
#     [2] __var="$(ls -1 / | ./mui.sh)"; echo "${__var}";
#     [3] . ./mui.sh -v "__var" < <(ls -1 /); echo "${__var}";
#     [4] . ./mui.sh; __mui_start -v__var < <(ls -1 /); echo "${__var}";
#
# Usage : __mui_start -v "var_name" [optional arguments]
#    or : ./mui.sh    [optional arguments]
#  Standard input (*required) : item list(with LF)
#  Arguments :
#    required* :
#      -v <var_name> : variables name to return selected values
#    optional  :
#      -p <var_name> : variables name to read/write \
#                       the cursor position on UI at start/exit
#      -m <number>   : max number of multiple selections
#      -s            : enable single selection (="-m 1")
#      -t <text>     : change UI title text
#      -i <number>   : set indent(bytes) of UI display
#      -r <number>   : max number of rows of UI body part
#      -n            : enable forward match / select by 'number key'
#
# Requirement :
#   bash-4.2          bash,read
#   coreutils-8.22    [,cat,echo,head,join,printf,sort,tail,uniq
#   gawk-4.0          awk
#   grep-2.20         grep
#   ncurses-5.9       tput
#   sed-4.2           sed
#   util-linux-2.23   column
#
# Author : hfftjp
#
#########################################################################
## start select menu UI
##   stdin   : item list(with LF) (*required)
##   args[*] : { -v <str>, -[imprt] <str/int>, -[ns] }
##     -v <var.name to return selected> (*required)
##     -p <var.name to save position>
##     -m <max of multi. select>       -s : single select mode, ="-m 1"
##     -t <menu title>                 -i <lines' indent>
##     -r <max rows per page>          -n : numeric key select mode
function __mui_start(){
  # local variables
  ## restore local var. __top & __pos from "-p" option.
  local __toppos="$( eval "echo -n \"\$$(
      echo "${@}" | sed -rn "s/^(|.*\s)\-p\s*(\S+)(\s.*|)$/{\2}/p" \
  )\"" )"; #"
  
  ## __list            : item list
  ## __select          : selected list
  ## __varname         : (outer) variables name for arg. "-v"
  ## __vartp           : (outer) variables name for arg. "-p"
  ## __top             : display top position in list
  ## __max             : line count of ${__list}
  ## __rows            : max number of display rows; for arg. "-r"
  ## __limit(__ldigit) : max number of rows to read stdin to ${__list}
  local __list=""       __select=""     __varname=""    __vartp=""  \
        __top=1         __pos=1         __min=1         __max=1     \
        __rows=1        __length=1      __ind=0         __multi=999 \
        __title=""      __footer=""     __selcld=1      __m_hbar="" \
        __in=""         __lastin=""     __numsel=0      __nextpos=0 \
        __limit=999     __ldigit=3;
  
  # functions
  ## fix pos
  function __mui_fix_pos(){
    (( __pos > __max && ( __pos = __max ) \
     , __pos < __min && ( __pos = __min ) ));
  }
  
  ## get value on cursor position
  function __mui_pos_val(){
    __mui_fix_pos; # fix pos
    echo "${__list}" | sed -n "${__pos}p";
  }
  
  ## update selected values list
  function __mui_upd_selected(){
    local __val="$(__mui_pos_val)";
    echo "${__select}" | grep -qFx "${__val}" \
      && { ## remove from list
           __select="$(echo "${__select}" | grep -vFx "${__val}")"; :; }\
      || { ## add to list
           [ $(__mui_lncnt "${__select}") -lt ${__multi} ] \
             && __select="$( echo -e "${__select}\n${__val}" \
                            | grep -vE "^\s*$" | sort | uniq )"; };
  }
  
  ## display title, body & footer ( arg[1]= 0:update, 1:init )
  function __mui_display(){
    # fix pos
    __mui_fix_pos;
    # fix top
    (( __top > (__max-__rows+1) && ( __top = __max-__rows+1 ) \
     , __top < __min            && ( __top = __min          ) \
     , __top > __pos            && ( __top = __pos          ) \
     , __top < (__pos-__rows+1) && ( __top = __pos-__rows+1 ) ));
    
    # title, body and footer
    join -t $'\v' -a 1 -1 1 -2 2 -o 2.1 1.1 -e ' ' \
      <(echo "${__list}" | sed -n "${__top},$((__top+__rows-1))p") \
      <(echo "${__select}" | sed -r "s/^/*\v/") \
      | sed -rn "s/^(.)\v[0-9]{${__ldigit}}:(.*)$/\1 \2/p" \
      | { [ "${__selcld}" -eq 1 ] \
          && { ## standard color
               sed -r 's/^/  /g' | sed -r \
               "$((__pos-__top+1))s/^  (..)(.*)$/=>\1\x1b[47m\2\x1b[0m/";
             } \
          || { ## text viewer color
               sed -r \
               "$((__pos-__top+1))s/^(.*)(\|.*)$/\1\x1b[4m\2\x1b[0m/";
             }; } \
      | awk -v "upd=${1:-0}"              \
            -v "rows=$((__rows+1))"       \
            -v "ind=${__ind}"             \
            -v "title=${__ind}${__title}" \
            -v "footer=$( echo -n "${__footer}" | \
                 sed -r -e "s|1+/2+|$(
                   printf "%${__ldigit}d/%${__ldigit}d" ${__pos} ${__max}
                 )|" \
                 -e "s|3+\)|$(
                   printf "%${__ldigit}d)" $(__mui_lncnt "${__select}")
                 )|")" \
            '{
               if(NR==1){
                 if(upd==0) printf "\x1b["rows"A\r";  ## for update
                 print title;
               };
               printf "%s%s\x1b[K\n",ind,gensub(/\t/," ","g",$0);
             }
             END{ printf "\r%s%s",ind,footer; }';
  }
  
  ## hashbar ( arg[1]:length )
  function __mui_hbar(){ echo -n "${__m_hbar:0:${1}}"; }
  
  ## create title/footer
  function __mui_fill_title_footer(){
    ## calc length
    ### __ldigit+1 : internal line number(and separator) for sort/join,
    ### +4 : arrow(2chars) + select mark(2chars) , +1 : right margin
    (( __length = $(__mui_wlen "${__list}")-(__ldigit+1)+4+1 \
     , __length < $(__mui_wlen "${__footer}") \
         && ( __length = $(__mui_wlen "${__footer}") ) \
     , __length < $(__mui_wlen "${__title}") \
         && ( __length = $(__mui_wlen "${__title}") ) ));
    
    ## title coloring and padding with hbar
    __title="$( echo -n "${__title}$(__mui_hbar \
      $((__length-$(__mui_wlen "${__title}"))) )" \
        | sed -r "s/(\S.*)$/\x1b[1;34m\1\x1b[0m\x1b[K/;" )";
    
    ## footer coloring and padding with hbar
    __footer="$( echo -n "${__footer}$( __mui_hbar \
       $((__length-$(__mui_wlen "${__footer}"))) )" \
        | sed -r -e "s/([A-Z]+)/\x1b[4m\1\x1b[0m\x1b[1;34m/g;" \
                 -e "s/(\S.*)$/\x1b[1;34m\1\x1b[0m\x1b[K\r/;" )";
  }
  
  ## show help
  function __mui_show_help(){
    local __prows=${__rows}; ## get parent values
    ## local override
    local __list=""       __select=""     __rows=${__prows}         \
          __max=1         __top=1         __pos=1         __in=""   \
          __title=""      __footer=""     __length=0      __selcld=0;
    
    ## set help text (with line number)
    __list="$(echo -n "${__MUI_M_MENU_HELP}" \
      | sed -r 's/(^\s*|\s*$)//g;/^$/d;s/^.//' | __mui_expand_tsv \
      | awk '{printf "%0'"${__ldigit}"'d:%2d| %s \n",NR,NR,$0}')";
    ## no text
    __max=$(__mui_lncnt "${__list}"); [ ${__max} -ge 1 ] || return 11;
    
    ## correct __rows
    (( __max < __prows && ( __rows = __max ) ));
    
    ## set help title/footer
    __title="$(__mui_hbar 3) ${__MUI_M_MENU_HELP_TITLE} ";
    __footer="$(__mui_hbar 3\
      ) ${__limit//9/1}/${__limit//9/2} ${__MUI_M_MENU_HELP_USAGE} ";
    __mui_fill_title_footer;
    
    ## help text coloring
    __list="$(echo -n "${__list}" \
      | sed -r 's/^([^|]+\|)(\s+#.*)$/\1\x1b[34;1m\2\x1b[0m/')";
    
    ## display help (and user key input)
    while __mui_display;
          __mui_readkey __in; do
      case "${__in}" in
        ## line/page move
        "${__MUI_K_UP}"    | "k" )  (( __pos-- ));;
        "${__MUI_K_DOWN}"  | "j" )  (( __pos++ ));;
        "${__MUI_K_LEFT}"  | "h" | "${__MUI_K_PGUP}" )
                (( __pos -= __rows , __top -= __rows ));;
        "${__MUI_K_RIGHT}" | "l" | "${__MUI_K_PGDOWN}" )
                (( __pos += __rows , __top += __rows ));;
        "${__MUI_K_HOME}" )  __pos=${__min};;
        "${__MUI_K_END}"  )  __pos=${__max};;
        ## exit help
        "" | "q" | "Q" | "${__MUI_K_ESC}" \
          | "${__MUI_K_BS}" | "${__MUI_K_DEL}" )  break;;
      esac;
    done;
    return 0;
  }
  
  ## optional value check and set
  function __mui_opt_set(){
    ## __local_var : (parent) variables name
    local __local_var="${1}" __opt_value="${2}" __default="${3}";
    ## __local_var($1) is null
    [ -n "${__local_var}" ] || return 1;
    
    ## check __opt_value($2)
    [[ "${__opt_value}" =~ ^-[a-zA-Z].*$ ]] \
      && { ## __opt_value($2) is not found
           [ -n "${__default}" ] \
             && eval "${__local_var}=\"${__default}\"";
           return 1; } \
      || { eval "${__local_var}=\"${__opt_value}\"";
           return 0; };
  }
  
  # processing
  ## set default
  ### for stdin read limit ( ldgit/limit -> multi )
  __ldigit="${__MUI_D_LDIGIT:-3}";
    [[ "${__ldigit}" =~ ^[1-9][0-9]*$ ]] || return 10;
  (( __limit = 10**__ldigit-1, __multi = __limit ));
  
  ### for title/footer ( titile/hashbar )
  __title="${__MUI_M_MENU_TITLE}";
  __m_hbar="$(printf "%.0s${__MUI_M_HASH:-=}" {1..500})";
  
  ### for body ( rows/top/pos )
  __rows=$(($(tput lines)-2));  ## 2 = title(1row) + footer(1row)
  [[ "${__toppos}" =~ ^[1-9][0-9]*:[1-9][0-9]*$ ]] \
    && { __top="${__toppos%:*}";
         __pos="${__toppos#*:}"; };
  
  ## read / check stdin
  [ -t 0 ] && return 11; ## no list
  __list="$(cat - | grep -vE "^\s*$" | head -${__limit} \
              | awk '{printf "%0'"${__ldigit}"'d:%s\n",NR,$0}')";
  __max=$(__mui_lncnt "${__list}"); [ ${__max} -ge 1 ] || return 11;
  
  ## read args.
  while [ -n "${1}" ]; do
    case "$1" in
      ## variables name to return selected
      -v   ) __mui_opt_set __varname "${2}"              && shift;;
      -v?* ) __mui_opt_set __varname "${1:2}"                    ;;
      
      ## variables name to read/write the cursor position
      -p   ) __mui_opt_set __vartp   "${2}"              && shift;;
      -p?* ) __mui_opt_set __vartp   "${1:2}"                    ;;
      
      ## max number of multiple selections / single selection
      -m   ) __mui_opt_set __multi   "${2}"   ${__limit} && shift;;
      -m?* ) __mui_opt_set __multi   "${1:2}"                    ;;
      -s   ) __mui_opt_set __multi   1                           ;;
      
      ## title text
      -t   ) __mui_opt_set __title   "${2}"              && shift;;
      -t?* ) __mui_opt_set __title   "${1:2}"                    ;;
      
      ## indent
      -i   ) __mui_opt_set __ind     "${2}"              && shift;;
      -i?* ) __mui_opt_set __ind     "${1:2}"                    ;;
      
      ## max number of display rows
      -r   ) __mui_opt_set __rows    "${2}"              && shift;;
      -r?* ) __mui_opt_set __rows    "${1:2}"                    ;;
      
      ## enable forward match by 'number key'
      -n   ) __mui_opt_set __numsel  1                           ;;
    esac;
    shift;
  done;
  
  ## check args.
  [[ "${__varname}"  =~ ^[_a-zA-Z][-_0-9a-zA-Z]*$ ]]   || return 12;
  [[ "${__vartp:-x}" =~ ^[_a-zA-Z][-_0-9a-zA-Z]*$ ]]   || return 13;
  [[ "${__multi}"    =~ ^[1-9][0-9]{0,${__ldigit}}$ ]] || return 14;
  [[ "${__ind}"      =~ ^[0-9]+$ ]]                    || return 15;
  __ind="$(printf "%${__ind}s")";
  [[ "${__rows}"     =~ ^[1-9][0-9]*$ ]]               || return 16;
  (( __rows > __max && ( __rows = __max ) ));
  
  ## set title/footer text
  __title="$(__mui_hbar 3) ${__title} $(__mui_hbar 3)";
  __footer="$(__mui_hbar 3) $(\
      [ ${__max} -eq ${__rows} ] \
        || echo -n "${__limit//9/1}/${__limit//9/2} ";
      [ ${__multi} -eq 1 ]       || echo -n '(*'${__limit//9/3}') ';
    )${__MUI_M_MENU_USAGE} $(__mui_hbar 3)";
  __mui_fill_title_footer; 
  
  ## init UI
  tput civis; # hide cursor
  __mui_display 1; # Initial display UI
  
  ## user input loop / update display UI
  while [ -n "${__in}" ] && __mui_display;
        __lastin="${__in}";
        __mui_readkey __in; do
    case "${__in}" in
      ## line/page move
      "${__MUI_K_UP}"    | "k" )  (( __pos-- ));;
      "${__MUI_K_DOWN}"  | "j" )  (( __pos++ ));;
      "${__MUI_K_LEFT}"  | "h" | "${__MUI_K_PGUP}" )
              (( __pos -= __rows , __top -= __rows ));;
      "${__MUI_K_RIGHT}" | "l" | "${__MUI_K_PGDOWN}" )
              (( __pos += __rows , __top += __rows ));;
      ## Home/End
      "${__MUI_K_HOME}" )  __pos=${__min};;
      "${__MUI_K_END}"  )  __pos=${__max};;
      
      ## move and select
      "K" ) [ ${__pos} -le ${__min} ] && continue;
            [ "${__lastin}" != "${__in}" ] && [ ${__multi} -gt 1 ] \
              && __mui_upd_selected;
            (( __pos-- ));
            [ ${__multi} -gt 1 ] && __mui_upd_selected;;
      "J" ) [ ${__pos} -ge ${__max} ] && continue;
            [ "${__lastin}" != "${__in}" ] && [ ${__multi} -gt 1 ] \
              && __mui_upd_selected;
            (( __pos++ ));
            [ ${__multi} -gt 1 ] && __mui_upd_selected;;
      
      ## jump to menu number (__numsel == 1)
      [0-9] ) [ ${__numsel} -eq 1 ] || continue;
        __nextpos="$(echo "${__list}"$'\n'"${__list}" \
          | tail -n +$((__pos+1)) \
          | sed -rn "/^[0-9]{${__ldigit}}:\s*${__in}/=" | head -1)";
        [ -n "${__nextpos}" ] && ((__pos=(__pos+__nextpos-1)%__max+1));
        if [ $(echo "${__list}" \
                 | grep -cE "^[0-9]{${__ldigit}}:\s*${__in}") -eq 1 ] \
           && [ ${__multi} -eq 1 ]; then
          __mui_display;
          __select="$(echo "${__list}" | sed -n "${__pos}p")";
          break;
        fi;;
      
      ## select all/none/invert (__multi > 1)
      "a" ) [ ${__multi} -gt 1 ] && [ ${__max} -le ${__multi} ] \
              && __select="${__list}";;
      "r" ) [ ${__multi} -gt 1 ] && __select="";;
      "i" ) [ ${__multi} -gt 1 ] \
              && [ $(( __max - $(__mui_lncnt "${__select}") )) \
                     -le ${__multi} ] \
              && __select="$(echo "${__list}"$'\n'"${__select}" \
                              | grep -vE "^\s*$" | sort | uniq -u )";;
      
      ## select, enter
      " " ) __mui_upd_selected;;
      ""  ) [ ${__multi} -eq 1 ] && __select="$(__mui_pos_val)"; break;;
      
      ## quit, help
      "q" | "Q" | "${__MUI_K_ESC}" \
        | "${__MUI_K_BS}" | "${__MUI_K_DEL}" ) __select=""; break;;
      "?" ) __mui_show_help;;
    esac;
    
    ## for single selection (__numsel == 1)
    [ ${__multi} -eq 1 ] && [ $(__mui_lncnt "${__select}") -eq 1 ] \
      && break;
    
  done;
  
  ## return cursor position
  [ -n "${__vartp}" ] && eval "${__vartp}=\"${__top}:${__pos}\"";
  
  ## return selected values
  eval "${__varname}=\"$(echo "${__select}" \
    | sed -r 's/^[0-9]{'"${__ldigit}"'}://')\"";
  
  echo ""; # print "\n" instead of traped "\n" by __mui_readkey
  tput cnorm; # show cursor
  
  return 0;
}
#########################################################################
## line count ( arg[1]:text lines )  / insted of wc -l
function __mui_lncnt(){ echo -n "${1}" | awk 'END{print NR}'; }

## get max line length ( arg[1]:text line[s] ) / insted of wc -c or ${#}
function __mui_wlen(){
  echo $(($(echo -n "$(echo $'\n'"${1}" \
    | sed -r -e 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g;s/\t/ /g;'\
             -e 's/^/x/;s/$/\v/' \
    | column -t -s$'\v' -o'x' | head -1)" | wc -c)-2));
}

## expand tabs("\t") from tsv text ( stdin: text ) / insted of expand
function __mui_expand_tsv (){
  cat - | sed -r 's/^|$/\t/g' | column -t -s$'\t' -o' ' \
        | sed -r 's/^ | $//g';
}

## key input ( arg[1]:variable name )
function __mui_readkey(){
  ## __varname : (outer) variables name to return user input key code
  local __buf="" __out="" __varname="${1}";
  [ -z "${__varname}" ] && return 1; # __varname is null
  
  ## get 1st byte
  IFS= read -rsn1 __buf </dev/tty;
  __out="${__buf}";
  
  ## for [ESC] + xxx
  if [ "${__out}" = $'\x1b' ]; then
    while IFS= read -rsn1 -t0.01 __buf </dev/tty; do
      ## [ESC]
      [ "${__buf}" = "" ] || [ "${__buf}" = $'\x1b' ] && break;
      
      __out="${__out}${__buf}";
      ## unknown
      [ "${__out:0:2}" = $'\x1b\x5b' ] || break;
      
      ## Ins,Home,End,PgUP,PgDown
      [ ${#__out} -eq 4 ] && [ "${__buf}" = $'\x7e' ] && break;
      
      ## len=5 (max) F1-F12
      [ ${#__out} -ge 5 ] && break;
      
      ## others
      case "${__out}" in
        ## Up,Down,Right,Left
        $'\x1b\x5b\x41' | $'\x1b\x5b\x42' | \
        $'\x1b\x5b\x43' | $'\x1b\x5b\x44' ) break;;
      esac;
      
    done;
  fi;
  
  ## return user input key code
  eval "${__varname}=\"${__out}\"";
  
  return 0;
}

#########################################################################
function __mui_init(){
  ## Messages text
  __MUI_M_MENU_TITLE='Select Menu';
  __MUI_M_MENU_USAGE='Quit,?:help';
  __MUI_M_MENU_HELP_TITLE='Help';
  __MUI_M_MENU_HELP_USAGE='Quit';
  __MUI_M_MENU_HELP='
    ##Cursor move :
    -  Line : {j,Down} {k,Up}
    -  Page : {l,PgDown,Right}
    -         {h,PgUp,Left}
    -  Etc. : Home End
    ##Select Item :
    -  Select : [SP]
    -  With Number : 0 - 9
    ##Select Item (Multiple):
    -  Select & Move :
    -    Shift + j / Shift + k
    -  All : a , None : r
    -  , Invert : i
    ##Exit :
    -  Exit  : [LF]
    -  Abort : {Q,[ESC],[BS]}';
  
  ## Keycode constant
  readonly \
  __MUI_K_ESC=$'\x1b' __MUI_K_BS=$'\x08' __MUI_K_DEL=$'\x7f'            \
  __MUI_K_UP=$'\x1b\x5b\x41'         __MUI_K_DOWN=$'\x1b\x5b\x42'       \
  __MUI_K_RIGHT=$'\x1b\x5b\x43'      __MUI_K_LEFT=$'\x1b\x5b\x44'       \
  __MUI_K_HOME=$'\x1b\x5b\x31\x7e'   __MUI_K_END=$'\x1b\x5b\x34\x7e'    \
  __MUI_K_PGUP=$'\x1b\x5b\x35\x7e'   __MUI_K_PGDOWN=$'\x1b\x5b\x36\x7e' \
  __MUI_K_INS=$'\x1b\x5b\x32\x7e'                                       \
  __MUI_K_F1=$'\x1b\x5b\x31\x31\x7e' __MUI_K_F2=$'\x1b\x5b\x31\x32\x7e' \
  __MUI_K_F3=$'\x1b\x5b\x31\x33\x7e' __MUI_K_F4=$'\x1b\x5b\x31\x34\x7e' \
  __MUI_K_F5=$'\x1b\x5b\x31\x35\x7e' __MUI_K_F6=$'\x1b\x5b\x31\x37\x7e' \
  __MUI_K_F7=$'\x1b\x5b\x31\x38\x7e' __MUI_K_F8=$'\x1b\x5b\x31\x39\x7e' \
  __MUI_K_F9=$'\x1b\x5b\x32\x30\x7e' __MUI_K_F10=$'\x1b\x5b\x32\x31\x7e'\
  __MUI_K_F11=$'\x1b\x5b\x32\x33\x7e'                                   \
  __MUI_K_F12=$'\x1b\x5b\x32\x34\x7e'                                   \
  2>/dev/null;
}

function __mui_final(){
  local __exitcd=$?;
  tput cnorm; # show cursor
  # stty sane;
  exit ${__exitcd};
}
#########################################################################
## call __mui_start
if [ "$BASH_SOURCE" = "${0}" ]; then
  # for sub-shell
  [ -t 0 ] && exit 1;  # no stdin
  
  # initialize
  trap '__mui_final' 0 1 2 3 15;  # bind finalize
  __mui_init;
  __MUI_SELECTED="";
  exec 3>&1- 1>/dev/tty;  # save stdout
  
  # call main part
  __mui_start "${@}" -v__MUI_SELECTED < <(cat -) || echo "ERROR:$?">&2;
  
  # return selected list to stdout/pipe
  echo "${__MUI_SELECTED}" >&3;
  
  # exec 1>&3-;
  exit 0;
  
else
  ## for source
  # initialize
  __mui_init;
  
  # call main part
  [ -t 0 ] || __mui_start -v__selval "${@}" < <(cat -);
  
fi;
