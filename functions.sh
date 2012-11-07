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

get_weather_data () {
    all_data=`awk "/future_day_$future_day/,/}/" $weather_data_file \
        | sed -e '1d' -e '$d' -e 's/^\s\+//'`
    if [ $data_type = "ALL" ]; then
        echo "$all_data"
    else
        echo "$all_data" | grep $data_type | awk -F= '{print $2}'
    fi
}

debug () {
    if [ $debug ]; then
        echo "[D] " $debug_prefix "$@"
    fi
}
# write_wt
# write_datatype
# complete_wfn

#
# functions.sh ends here
