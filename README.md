# mui-sh
"mui.sh" - select "M"enu "UI" script for bash.

## Example of use :
* call by source
  ``` shell
  ls -1 / | source ./mui.sh -r 7 | paste -sd,  
  ```
  ``` shell
  source ./mui.sh;  ## First time only
  __mui_start -v__var < <(ls -1 /); echo "${__var}";
  ```
  ``` shell
  source ./mui.sh;  ## First time only
  echo "$(ls -1 / | __mui_start -r 5 -i 3)";
  ```
* display example 
  ```
  # ls -1 / | source ./mui.sh -r 7 | paste -sd,
  == menu ========
      bin
      boot
      dev
    * etc
    * home
  =>* lib
      lib64
  ==  6/21(* 3) ==
  ```

## Usage :
```
Usage : __mui_start [optional arguments]

 Standard input (*required) : item list(with LF)

 Standard output (optional) : return selected list(with LF)

 Arguments :
   optional  :
     -v <var_name> : variables name to return selected values
     -p <var_name> : variables name to read/write \
                      the cursor position on UI at start/exit
     -m <number>   : max number of multiple selections
     -s            : enable single selection (="-m 1")
     -t <text>     : change UI title text
     -i <number>   : set indent(bytes) of UI display, \
                      and "ESC [ K" cmd is disabled
     -r <number>   : max number of rows of UI body part
     -n            : enable forward match / select by 'number key'
     -w <number>   : set width(bytes) of UI, if possible
     -A            : hide cursor mark "=>"
```
---
## Requirement :
| command                                     | pkg.(example)    |
| ---                                         | ---              |
| bash,read                                   | bash-4.2         |
| \[,cat,echo,head,join,printf,sort,tail,uniq | coreutils-8.22   |
| awk                                         | gawk-4.0         |
| grep                                        | grep-2.20        |
| tput                                        | ncurses-5.9      |
| sed                                         | sed-4.2          |
| column                                      | util-linux-2.23  |



