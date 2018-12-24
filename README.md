# mui-sh
"mui.sh" - select "M"enu "UI" script for bash.

## Example of use :
* call by bash
  ``` shell
  ls -1 / | ./mui.sh | grep -En '';  
  ```
  ``` shell
  __var="$(ls -1 / | ./mui.sh)"; echo "${__var}";  
  ```
* call by source
  ``` shell
  source ./mui.sh -v "__var" < <(ls -1 /); echo "${__var}";  
  ```
  ``` shell
  source ./mui.sh;  ## First time only
  __mui_start -v__var < <(ls -1 /); echo "${__var}";
  ```
* display example 
  ```
  # ls -1 / | ./mui.sh -r7
  === Select Menu ==================
      bin
      boot
  =>  dev
      etc
      home
      lib
      lib64
  ===   3/ 21 (*  0) Quit,?:help ===
  ```

## Usage :
```
Usage : __mui_start -v "var_name" [optional arguments]
   or : ./mui.sh    [optional arguments]

Standard input (*required) : item list(with LF)

Arguments :
  required* :
    -v <var_name> : variables name to return selected values
  optional  :
    -p <var_name> : variables name to read/write \
                     the cursor position on UI at start/exit
    -m <number>   : max number of multiple selections
    -s            : enable single selection (="-m 1")
    -t <text>     : change UI title text
    -i <number>   : set indent(bytes) of UI display
    -r <number>   : max number of rows of UI body part
    -n            : enable forward match / select by 'number key'
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



