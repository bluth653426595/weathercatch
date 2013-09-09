# baidu.sh ---
#
# Filename: baidu.sh
# Description: a parser fo weathercatch
# Author: Xu FaSheng
# Created: 2012.11.06
# Keywords: weathercatch parser baidu

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


parser_name="baidu"
default_arg="天气"
debug "parser_name: $parser_name"

update_weather_data () {
    if [ ! "$arg" ]; then arg="$default_arg"; fi
    URL="www.baidu.com/s?wd=$arg"
    URL=`convert_url_space "$URL"`

    # dump web page
    debug "dumping url: $URL"
    web_content=`retry_cmd 3 timeout_cmd 15s w3m -dump -no-cookie "$URL"`
    if [ -n "$web_content" ]; then
        echo "$web_content">$weather_tmp_file
        parse_data
    fi
}

parse_data () {
    # get valid AQI info section in the page
    aqi_block=`get_section_file $weather_tmp_file "空气质量指数" "空气质量细分数据"`
    debug_lines "AQI block:" "$aqi_block"

    # get AQI value
    # remove first line and empty lines
    aqi_block=`echo "$aqi_block" | sed -e '1d' -e '/^$/d'`
    AQI=`echo "$aqi_block" | head -1 | sed 's/^\([0-9]\+\)$/\1/'`

    # get AQI description
    AQID=`echo "$aqi_block" | head -2 | tail -1`

    # get AQI tips
    AQIT=`echo "$aqi_block" | grep '温馨提示' | sed 's/温馨提示：\(.*\)。/\1/'`

    # get valid weather info section in the page
    weather_block=`get_section_file $weather_tmp_file "一周天气预报" "中国气象局"`
    debug_lines "weather block:" "$weather_block"

    # get location name
    LN=`echo "$weather_block" | head -1 | sed 's/天气预报.*$//'`

    # get other weather data
    weather_block=`echo "$weather_block" | sed -e '1d' -e '$d' | awk 'NF>1'`
    weather_block=`clear_w3m_target_block "$weather_block" "[neverfill]"`
    weather_block=`clear_w3m_target_block "$weather_block" "[u]"`
    debug_lines "weather block[fixed]" "$weather_block"
    weather_block=`reverse_table "$weather_block"`
    i=0
    while read line; do
        debug "future_day_$i"
        set_data_type "LN" $LN

        # temperature
        temp_data=`echo $line | awk '{print $2}'`
        temp_left=`echo $temp_data | awk -F～ '{print $1}' | sed 's/\(-\?[0-9]\+\).*/\1/'`
        temp_right=`echo $temp_data | awk -F～ '{print $2}' | sed 's/\(-\?[0-9]\+\).*/\1/'`
        # there is only low temp in tonight
        if [ -n $temp_right ]; then
            HT=$temp_left
            LT=$temp_right
        else
            HT=
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

        # AQI info only exists today
        if [ $i -eq 0 ]; then
            set_data_type "AQI" $AQI
            set_data_type "AQID" $AQID
            set_data_type "AQIT" $AQIT
        fi

        write_data_types $i
        i=$(($i+1))
    done <<< "$weather_block"
}

parser_help () {
    cat <<EOF
Homepage: www.baidu.com
Argument meaning:
    The keyword to search which results will own weather info you
    expect, in fact, it just could be a city name.
    [default: "$default_arg"]
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
    AQI: AQI(air quality index) value
    AQID:AQI description
    AQIT:AQI tips
Support max future days: 2
Depends:
    w3m v0.5.3+
Compatibility:
    works well on weathercatch_v0.2
    May work on older versions but this is not guaranteed.
Limits:
    Should only work for Chinese friends.
EOF
}

parser_version () {
    echo "build 20130411"
}

debug "parser load success"


#
# baidu.sh ends here
