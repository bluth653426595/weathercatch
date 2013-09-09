# functions.sh ---
#
# Filename: functions.sh
# Description: assistent functions for weathercatch
# Author: Xu FaSheng
# Created: 2012.11.06
# Last-Updated:
#           By:
#     Update #: 0
# Keywords: assistant function

# This file is a part of weathercatch

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth
# Floor, Boston, MA 02110-1301, USA.
#
#

# Code:


float_round_off () {
    awk -v float=$1 '
BEGIN {
  CONVFMT="%d";
  i=float+0 "";
  d=float-i;
  if (d<0.5)
    print i;
  else
    print i+1;
}'
}

# temperature, Celsius -> Fahrenheit
temp_c2f () {
    float_round_off `awk "BEGIN {print $1*9/5+32}"`
}

# temperature, Fahrenheit -> Celsius
temp_f2c () {
    float_round_off `awk "BEGIN {print ($1-32)*5/9}"`
}

is_night_now () {
    hour=`date +%H`
    if [[ $hour -ge 18 || `date +%H` -le 6 ]]; then
        echo "t"
    fi
}

# weather font, auto mode
wf_automode () {
    if [ `is_night_now` ]; then
        wf_nightmode "$1"
    else
        wf_daymode "$1"
    fi
}

# weather font, use day mode
wf_daymode () {
    echo "$1" | tr "Olmnopqrstu" "Dbcdefghijk"
}

# weather font, use night mode
wf_nightmode () {
    echo "$1" | tr "Dbcdefghijk" "Olmnopqrstu"
}

set_data_type () {
    name="$1"
    value="$2"
    if [ -z "$data_types_to_write" ]; then
        data_types_to_write="$name=$value"
    else
        data_types_to_write="$data_types_to_write"$'\n'"$name=$value"
    fi
    debug "  $name=$value"
}

write_data_types () {
    # if first time write data, clear the old data
    if [ ! $old_data_is_cleared ]; then
        echo > $weather_data_file
        old_data_is_cleared=t
        debug "old data is cleared"
    fi

    echo "future_day_$1 () {" >> $weather_data_file
    echo "$data_types_to_write" >> $weather_data_file
    echo "}" >> $weather_data_file
    data_types_to_write=
}

do_get_weather_data () {
    # debug "do_get_weather_data: $data_type" ;;TODO
    all_data=`awk "/future_day_$future_day/,/}/" $weather_data_file \
        | sed -e '1d' -e '$d' -e 's/^\s\+//'`
    if [ "$data_type" = "ALL" ]; then
        echo "$all_data"
        return
    fi
    echo "$all_data" | grep -e "^$data_type=" | awk -F= '{print $2}'
}

get_weather_data () {
    # operate hook first
    # don't use "$()" when run get_weather_data_hook() to enable it
    # modify global variables TODO
    debug "data type[before hook]: $data_type"
    get_weather_data_hook
    debug "data type[after hook]: $data_type"
    if [ -n "$hook_result" ]; then
        echo "$hook_result"
        return
    fi

    # get value in data file
    value=`do_get_weather_data`
    debug_lines "value(s):" "$value"

    # result effect
    case "$data_type" in
        WF)                    # weather font, check day or night mode
            value=`general_wf_auto_select_day_or_night "$value"`;;
        LT|HT|CT)               # temperature unit
            # default temp unit in data file should be celsius
            if [ "$temp_unit" = "f" ]; then
                value=`temp_c2f "$value"`
            fi;;
    esac
    echo "$value"
}

# a b c    a 1
# 1 2 3 -> b 2
#          c 3
reverse_table () {
    echo "$1" | awk '
{
  if (max_nf < NF) max_nf=NF
  max_nr=NR
  for(i=1; i<=NF; i++)
    vector[i, NR]=$i
}
END {
  for(i=1; i<=max_nf; i++) {
    for(j=1; j<=max_nr; j++)
      printf("%s ", vector[i, j])
    printf("\n")
  }
}'
}

# a    b           [target]      a  b  c
# 1    [target]    c         ->  1  2  3
#      2           3
clear_w3m_target_block () {
    fixed_table=`echo "$1" | sed "s/^  /$2/"`
    reversed_table=`reverse_table "$fixed_table"`
    cleared_table=`echo "$reversed_table" | awk -v tb=$2 '
{
  for(i=1; i<=NF; i++) {
    if ($i !~ tb)
      printf("%s ", $i)
  }
  printf("\n")
}'`
    reverse_table "$cleared_table"
}

convert_url_space () {
    echo "$1" | sed 's/ /%20/g'
}

retry_cmd () {
    local retry_time=$1
    local cmd="${@:2}"
    for((i=1; i<=$retry_time; i++)); do
        if $cmd; then
            break
        fi
    done
}

timeout_cmd () {
    local timeout=$1
    local cmd="${@:2}"
    # if exist 'timeout' command, use it
    if command -v timeout >/dev/null 2>&1; then
        timeout $timeout $cmd
    else
        $cmd
    fi
}

# output a matched section in a file, support regexp for the start and
# end match word, and include start and end line in output
get_section_file () {
    local file="$1"
    local start="$2"
    local end="$3"
    awk "
/$start/{enable_print=1}
enable_print{print}
/$end/{if (enable_print) exit}
" $file
}

# output a matched section in a multiline sting, support regexp for
# the start and end match word, and include start and end line in
# output
get_section_string () {
    local strings="$1"
    local start="$2"
    local end="$3"
    echo "$strings" | awk "
/$start/{enable_print=1}
enable_print{print}
/$end/{if (enable_print) exit}
"
}

general_wf_auto_select_day_or_night () {
    if [ "$night_mode" = "day" ]; then
        wf_daymode "$1"
    elif [ "$night_mode" = "night" ]; then
        wf_nightmode "$1"
    elif [ "$night_mode" = "auto" ]; then
        wf_automode "$1"
    fi
}

general_weather_text2font_cn () {
    case "$1" in
        *雾*)           echo 'F';;
        *台风*|*飓风*)   echo 'v';;
        *龙卷风*)        echo 'w';;
        *中雪*|*大雪*)   echo 'k';;
        *雪*)           echo 'j';;
        *雷*雨*|*雨*雷*) echo 'i';;
        *雷*)           echo 'f';;
        *中雨*|*大雨*|*暴雨*) echo 'h';;
        *雨*)           echo 'g';;
        *多云转晴*|*晴转多云*) echo 'b';;
        *多云*)         echo 'd';;
        *晴*)           echo 'D';;
        *阴*)           echo 'e';;
        '')echo '';;
        *) echo 'A';;
    esac
}

#
# functions.sh ends here
