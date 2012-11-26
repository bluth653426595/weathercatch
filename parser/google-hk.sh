# google-hk.sh ---
#
# Filename: google-hk.sh
# Description: a parser fo weather_catcher
# Author: Xu FaSheng
# Created: 2012.11.12
# Keywords: weather_catcher parser google-hk

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


# depend on parser google
parent_script=`get_parser_script google`
source "$parent_script"

parser_name="google-hk"
default_arg="weather hongkong"
debug "parser_name: $parser_name"

update_weather_data () {
    if [ -z "$arg" ]; then arg="$default_arg"; fi

    URL="https://www.google.com.hk/search?q=$arg"
    URL=`convert_url_space "$URL"`

    # dump web page
    debug "dumping url: $URL"
    web_content=`retry_cmd 3 timeout_cmd 15s w3m -dump -no-cookie "$URL"`
    if [ -n "$web_content" ]; then
        echo "$web_content">$weather_tmp_file
        parse_data
    fi
}

parse_location () {
    LN=`echo "$weather_block" | head -1 | sed 's/^.*\s\(.*\)天氣$/\1/'`
}

simplify_weather_block () {
    weather_block=`get_section_string "$weather_block" "[0-9]+°C" "濕度："`
    weather_block=`echo "$weather_block" | sed -e 's/^ *• \?//'`
    weather_block=`echo "$weather_block" | sed 's/^\(\S\+\s\)\+//'`

    # delete unicode characters, 0x200e
    weather_block=`echo "$weather_block" | sed 's/‎\(.\)/\1/g'`

    # delete prefix spaces
    weather_block=`echo "$weather_block" | sed 's/^ \+//'`

    debug_lines "weather block[fixed]" "$weather_block"
}

parse_left_weather_block () {
    # get weather tag
    local weather_tag=`echo "$left_weather_block" | sed -n '/\[.*\]/p' | sed 's/\(\[.*\]\).*/\1/'`
    left_weather_block=`echo "$left_weather_block" | sed 's/\[.*\]//'`

    # current weather font
    CWF=`google_weather_tag2wf "$weather_tag"`

    # current temperature
    CT=`echo "$left_weather_block" | sed -n 1p | tr -d '°C'`

    # current weather text
    CWT=`echo "$left_weather_block" | sed -n 2p | sed -e 's/^\s*//' -e 's/\s*$//'`

    # wind direction
    WD=`echo "$left_weather_block" | sed -n 3p | awk -F'，' '{print $1}' | awk -F'：' '{print $2}'`

    # wind speed
    WS=`echo "$left_weather_block" | sed -n 3p | awk -F'，' '{print $2}' | awk -F'：' '{print $2}' | awk '{print $1}'`

    # humidity
    HM=`echo "$left_weather_block" | sed -n '$p' | awk -F'：' '{print $2}' | tr -d '%'`
}

# convert weather tag in google to weather text
google_weather_tag2wt () {
    local tag=`echo "$1" | tr -d '[]'`
    # TODO complete all rules
    case "$tag" in
        fog) echo '有霾';;
        # typhoon|hurricane) echo '';;
        # tornado) echo '';;
        light_s) echo '小雪';;
        sno|snow) echo '雪';;
        tst) echo '雷陣雨';;
        # thunder) echo '';;
        light_r) echo '小雨';;
        rai|rain) echo '雨';;
        par) echo '多雲時晴';;
        partly_) echo '多雲時陰';;
        clo) echo '多雲';;
        cloudy) echo '陰';;
        sun) echo '晴';;
        lig) echo '有雨/雪';;
        '')echo '';;
        *) echo '未知';;
    esac
}

parser_version () {
    echo "build 20121126"
}

debug "parser load success"


#
# google-hk.sh ends here
