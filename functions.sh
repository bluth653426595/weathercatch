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
    all_data=`awk "/future_day_$future_day/,/}/" $weather_data_file \
        | sed -e '1d' -e '$d' -e 's/^\s\+//'`
    if [ $data_type = "ALL" ]; then
        echo "$all_data"
    else
        # TODO
        echo "$all_data" | grep $data_type | awk -F= '{print $2}'
    fi
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
    if echo "$1" | grep -Eiq '雾'; then
        echo 'F'
    elif echo "$1" | grep -Eiq '台风|飓风'; then
        echo 'v'
    elif echo "$1" | grep -Eiq '龙卷风'; then
        echo 'w'
    elif echo "$1" | grep -Eiq '中雪|大雪'; then
        echo 'j'
    elif echo "$1" | grep -Eiq '雪'; then
        echo 'k'
    elif echo "$1" | grep -Ei '雷' | grep -Eiq '雨'; then
        echo 'i'
    elif echo "$1" | grep -Eiq '雷'; then
        echo 'f'
    elif echo "$1" | grep -Eiq '中雨|大雨|暴雨'; then
        echo 'h'
    elif echo "$1" | grep -Eiq '雨'; then
        echo 'g'
    elif echo "$1" | grep -Eiq '多云转晴|晴转多云'; then
        echo 'b'
    elif echo "$1" | grep -Eiq '多云'; then
        echo 'c'
    elif echo "$1" | grep -Eiq '晴'; then
        echo 'a'
    elif echo "$1" | grep -Eiq '阴'; then
        echo 'e'
    else
        echo 'D'
    fi
}

#
# functions.sh ends here
