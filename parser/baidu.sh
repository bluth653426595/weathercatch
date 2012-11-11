# baidu.sh ---
#
# Filename: baidu.sh
# Description: a parser fo weather_catcher
# Author: Xu FaSheng
# Created: 2012.11.06
# Keywords: weather_catcher parser

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


parser_name="baidu"
debug "parser_name: $parser_name"

update_weather_data () {
    if [ ! "$arg" ]; then arg="weather"; fi
    URL="www.baidu.com/s?wd=$arg"
    URL=`convert_url_space "$URL"`

    # dump web page
    debug "dumping url: $URL"
    web_content=`timeout_cmd w3m -dump -no-cookie "$URL"`
    if [ -n "$web_content" ]; then
        echo "$web_content">$weather_tmp_file
    fi

    parse_data
}

parse_data () {
    # get valid weather info section in the page
    weather_block=`get_section_file $weather_tmp_file "一周天气预报" "中国气象局"`
    debug "weather block:"
    debug_lines "$weather_block"

    # get location name
    LN=`echo "$weather_block" | head -1 | sed 's/天气预报.*$//'`

    # get other weather data
    weather_block=`echo "$weather_block" | sed -e '1d' -e '$d' | awk 'NF>1'`
    weather_block=`clear_w3m_target_block "$weather_block" "[neverfill]"`
    debug "weather block[fixed]"
    debug_lines "$weather_block"
    weather_block=`reverse_table "$weather_block"`
    i=0
    while read line; do
        debug "future_day_$i"
        set_data_type "LN" $LN

        # temperature
        temp_data=`echo $line | awk '{print $2}'`
        temp_left=`echo $temp_data | awk -F～ '{print $1}' | sed 's/\(-\?[0-9]\+\).*/\1/'`
        temp_right=`echo $temp_data | awk -F～ '{print $2}' | sed 's/\(-\?[0-9]\+\).*/\1/'`
        if [ -z $temp_right ]; then temp_right=$temp_left; fi
        if [ $temp_left -ge $temp_right ]; then
            HT=$temp_left
            LT=$temp_right
        else
            HT=$temp_right
            LT=$temp_left
        fi
        set_data_type "LT" $LT
        set_data_type "HT" $HT

        # weather text
        WT=`echo $line | awk '{print $3}'`
        set_data_type "WT" $WT

        # weather font
        WF=`general_weather_text2font_cn "$WT"`
        set_data_type "WF" $WF

        # wind speed text
        WST=`echo $line | awk '{print $4}'`
        set_data_type "WST" $WST

        write_data_types $i
        i=$(($i+1))
    done <<< "$weather_block"
}

parser_help () {
    cat <<EOF
Argument meaning:
    The keyword to search which results will own weather info you
    expect, in fact, it just could be a city name.
    [default: weather]
Support data types:
    WF:  weather font output
         [effect by --night-mode]
    WT:  weather text
    LT:  low temperature
         [default unit: celsius]
         [effect by --temp-unit]
    HT:  high temperature
         [default unit: celsius]
         [effect by --temp-unit]
    WST: wind speed text
    LN:  location name
Support max future days: 2
Depends:
    w3m v0.5.3+
Compatibility:
    works well on weather_catcher_v0.2
    May work on older versions but this is not guaranteed.
Limits:
    Should only work for Chinese friends.
EOF
}

parser_version () {
    echo "build 20121112"
}

debug "parser load success"


#
# baidu.sh ends here
