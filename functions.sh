# functions.sh ---
#
# Filename: functions.sh
# Description: assistent functions for weather_catcher
# Author: Xu FaSheng
# Created: 2012.11.06
# Last-Updated:
#           By:
#     Update #: 0
# Keywords: assistant function

# This file is a part of weather_catcher

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

# weather font, auto mode
wf_automode () {
    if [ `date +%H` -ge 18 ]; then
        wf_nightmode $1
    else
        wf_daymode $1
    fi
}

# weather font, use day mode
wf_daymode () {
    echo $1 | tr "Olmnopqrstu" "abcdefghijk"
}

# weather font, use night mode
wf_nightmode () {
    echo $1 | tr "abcdefghijk" "Olmnopqrstu"
}

set_data_type () {
    name=$1
    value=$2
    if [ -z $data_types_to_write ]; then
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

get_weather_data () {
    # operate hook first
    hook_result=`get_weather_data_hook`
    if [ -n "$hook_result" ]; then
        echo "$hook_result"
        return
    fi

    all_data=`awk "/future_day_$future_day/,/}/" $weather_data_file \
        | sed -e '1d' -e '$d' -e 's/^\s\+//'`
    if [ "$data_type" = "ALL" ]; then
        echo "$all_data"
        return
    fi
    value=`echo "$all_data" | grep $data_type | awk -F= '{print $2}'`
    case "$data_type" in
        WF)                     # weather font, check day or night mode
            if [ "$night_mode" = "day" ]; then
                value=`wf_daymode "$value"`
            elif [ "$night_mode" = "night" ]; then
                value=`wf_nightmode "$value"`
            elif [ "$night_mode" = "auto" ]; then
                value=`wf_automode "$value"`
            fi;;
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
    fixed_table=`echo "$1" | sed 's/^  /$2/'`
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

general_weather_text2font_cn () {
    case "$1" in
        *雾*)           echo 'F';;
        *台风*|*飓风*)   echo 'v';;
        *龙卷风*)        echo 'w';;
        *中雪*|*大雪*)   echo 'j';;
        *雪*)           echo 'k';;
        *雷*雨*|*雨*雷*) echo 'i';;
        *雷*)           echo 'f';;
        *中雨*|*大雨*|*暴雨*) echo 'h';;
        *雨*)           echo 'g';;
        *多云转晴*|*晴转多云*) echo 'b';;
        *多云*)         echo 'c';;
        *晴*)           echo 'a';;
        *阴*)           echo 'e';;
        *) echo 'D';;
    esac
}

#
# functions.sh ends here
