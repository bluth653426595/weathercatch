# google.sh ---
#
# Filename: google.sh
# Description: a parser fo weather_catcher
# Author: Xu FaSheng
# Created: 2012.11.12
# Keywords: weather_catcher parser google

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


parser_name="google"
default_arg="weather san francisco"
debug "parser_name: $parser_name"

update_weather_data () {
    if [ -z "$arg" ]; then arg="$default_arg"; fi

    # use "74.125.31.103" instead of "www.google.com" to
    # ensure the web page is in english
    URL="http://74.125.31.103/search?q=$arg"
    URL=`convert_url_space "$URL"`

    # dump web page
    debug "dumping url: $URL"
    web_content=`retry_cmd 3 timeout_cmd 5s w3m -dump -no-cookie "$URL"`
    if [ -n "$web_content" ]; then
        echo "$web_content">$weather_tmp_file
        parse_data
    fi
}

parse_data () {
    # get valid weather info section in the web page
    get_valid_weather_section

    # get location name, should in the first line of $weather_block
    parse_location

    simplify_weather_block

    # split $weather_block vertical, the left part should be current
    # weather info, the right part should be weather thumbnail for
    # today and future
    split_weather_block_vert

    parse_left_weather_block
    parse_right_weather_block
}

get_valid_weather_section () {
    weather_block=`get_section_file $weather_tmp_file " 1\.$" " 2\. "`
    weather_block=`echo "$weather_block" | sed -e '1d' -e '$d'`
    debug_lines "weather block:" "$weather_block"
}

parse_location () {
    LN=`echo "$weather_block" | head -1 | sed 's/^.*Weather for \(.*\)$/\1/'`
}

simplify_weather_block () {
    weather_block=`get_section_string "$weather_block" "[0-9]+°C" "Humidity:"`
    weather_block=`echo "$weather_block" | sed -e 's/^ *• \?//'`
    weather_block=`echo "$weather_block" | sed 's/^\(\S\+\s\)\+//'`

    # delete unicode characters, 0x200e
    weather_block=`echo "$weather_block" | sed 's/‎\(.\)/\1/g'`

    # delete prefix spaces
    weather_block=`echo "$weather_block" | sed 's/^ \+//'`

    debug_lines "weather block[fixed]" "$weather_block"
}

split_weather_block_vert () {
    left_weather_block=`echo "$weather_block" | awk -F' {2,}' '{print $1}'`
    right_weather_block=`echo "$weather_block" | awk -F' {2,}' '{print substr($0, length($1)+2)}' | awk 'NF>1' | sed 's/^\s*//'`
    debug_lines "left weather block" "$left_weather_block"
    debug_lines "right weather block" "$right_weather_block"
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
    WD=`echo "$left_weather_block" | sed -n 3p | awk '{print $2}'`

    # wind speed
    WS=`echo "$left_weather_block" | sed -n 3p | awk '{print $4}'`

    # humidity
    HM=`echo "$left_weather_block" | sed -n 4p | awk '{print $2}' | tr -d '%'`
}

parse_right_weather_block () {
    for((i=0; i<4; i++)); do
        debug "future_day_$i"
        set_data_type "LN" $LN

        # mark current weather info
        if [ $i -eq 0 ]; then
            set_data_type "CT" $CT
            set_data_type "CWT" $CWT
            set_data_type "CWF" $CWF
            set_data_type "WD" $WD
            set_data_type "WS" $WS
            set_data_type "HM" $HM
        fi

        # weather font
        local weather_tag=`echo "$right_weather_block" | sed -n 2p | awk -v i=$(($i+1)) '{print $i}'`
        WF=`google_weather_tag2wf "$weather_tag"`
        set_data_type "WF" $WF

        # weather text
        WT=`google_weather_tag2wt "$weather_tag"`
        set_data_type "WT" $WT

        # high temperature
        HT=`echo "$right_weather_block" | sed -n 3p | awk -v i=$(($i*2+1)) '{print $i}' | tr -d °`
        set_data_type "HT" $HT

        # low temperature
        LT=`echo "$right_weather_block" | sed -n 3p | awk -v i=$(($i*2+2)) '{print $i}' | tr -d °`
        set_data_type "LT" $LT

        write_data_types $i
    done
}

# convert weather tag in google to weather font
google_weather_tag2wf () {
    local tag=`echo "$1" | tr -d '[]'`
    # TODO complete all rules
    case "$tag" in
        fog) echo 'F';;
        # typhoon|hurricane) echo 'v';;
        # tornado) echo 'w';;
        light_s) echo 'j';;
        sno|snow) echo 'k';;
        tst|tstorms) echo 'i';;
        # t*) echo 'f';;
        light_r) echo 'g';;
        rai|rain) echo 'h';;
        par) echo 'b';;
        partly_) echo 'c';;
        clo) echo 'd';;
        cloudy) echo 'e';;
        sun) echo 'D';;
        lig) echo 'e';;
        '')echo '';;
        *) echo 'A';;
    esac
}

# convert weather tag in google to weather text
google_weather_tag2wt () {
    local tag=`echo "$1" | tr -d '[]'`
    # TODO complete all rules
    case "$tag" in
        fog) echo 'Hale';;
        # typhoon|hurricane) echo '';;
        # tornado) echo '';;
        light_s) echo 'Light Snow';;
        sno|snow) echo 'Snow';;
        tst|tstorms) echo 'Thunderstorms';;
        # thunder) echo '';;
        light_r) echo 'Light Rain';;
        rai|rain) echo 'Rain';;
        par) echo 'Mostly Sunny';;
        partly_) echo 'Partly Cloudy';;
        cloudy) echo 'Overcast';;
        clo) echo 'Cloudy';;
        sun) echo 'Sunny';;
        lig) echo 'Chance of rain/snow';;
        '')echo '';;
        *) echo 'Unknown';;
    esac
}

get_weather_data_hook () {
    hook_result=

    # result effect for special data types
    value=`do_get_weather_data`
    case "$data_type" in
        CWF)
            value=`general_wf_auto_select_day_or_night "$value"`
            hook_result="$value";;
    esac
}

parser_help () {
    cat <<EOF
Homepage: www.google.com
Argument meaning:
    The keyword to search which results will own weather info you
    expect, in fact, it just could be "weather cityname".
    [default: "$default_arg"]
Support data types:
    WF:  weather font output
         [effect by --night-mode]
    WT:  weather text
    CWF: current weather font output
         [effect by --night-mode]
    CWT: current weather text
    CT:  current temperature
         [default unit: celsius]
         [effect by --temp-unit]
    LT:  low temperature
         [default unit: celsius]
         [effect by --temp-unit]
    HT:  high temperature
         [default unit: celsius]
         [effect by --temp-unit]
    WD:  wind direction
    WS:  wind speed
         [default unit: kmh]
    HM:  humidity
         [default unit: percent]
    LN:  location name
Support max future days: 3
Depends:
    w3m v0.5.3+
Compatibility:
    works well on weather_catcher_v0.2
    May work on older versions but this is not guaranteed.
EOF
}

parser_version () {
    echo "build 20130411"
}

debug "parser load success"


#
# google.sh ends here
