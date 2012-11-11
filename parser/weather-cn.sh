# weather-cn.sh ---
#
# Filename: weather-cn.sh
# Description: a parser fo weather_catcher
# Author: Xu FaSheng
# Created: 2012.11.09
# Keywords: weather_catcher parser
# Compatibility: weather_catcher_v0.1
#   depends on w3m v0.5.3
#   May work on older versions but this is not guaranteed.
#

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


parser_name="weather-cn"
debug "parser_name: $parser_name"

update_weather_data () {
    if [ ! "$arg" ]; then
        arg="www.weather.com.cn/weather/101010100.shtml"
    fi
    URL="$arg"
    URL=`convert_url_space "$URL"`

    # dump web page
    web_content=`timeout_cmd w3m -dump -no-cookie "$URL"`
    if [ -n "$web_content" ]; then
        echo "$web_content">$weather_tmp_file
    fi

    parse_data
}

parse_data () {
    # get valid weather info section in the page
    weather_block=`get_section_file $weather_tmp_file "天气图例" "周边地区[今明]日天气"`
    debug "weather block:"
    debug_lines "$weather_block"

    # get location name
    LN=`echo "$weather_block" | head -1 | sed 's/天气预报.*$//'`

    # get other weather data
    weather_block=`echo "$weather_block" | sed -e '1d' -e '$d' -e '/^.\?$/d' -e '/未来4-7天天气预报/d'`
    debug "weather block[fixed]"
    debug_lines "$weather_block"
    days_count=`echo "$weather_block" | awk -v RS='星期' 'END{print NR}'`
    debug "days_count: $days_count"
    for ((i=2; i<=$days_count; i++)); do
        # the first valid record start as index 2
        daynum=$(($i-2))
        debug "future_day_$daynum"
        set_data_type "LN" $LN
        day_weather_block=`echo "$weather_block" | awk -v RS='星期' -v i=$i 'NR==i'`

        # weather info on day(maybe is disappeared)
        dayinfo=`echo "$day_weather_block" | awk -v RS='夜间' 'NR==1'`
        dayinfo=`echo "$dayinfo" | tr '\n' ' '` # skip newlines
        debug "  dayinfo#$daynum: $dayinfo"

        # weather text on day, if is a long text, it will append at
        # second line, and after parsing, it will appear as $9
        WTD=`echo "$dayinfo" | awk '{if ($(10))print $4$9; else print $4}'`
        set_data_type "WTD" $WTD

        # weather font on day
        WFD=`general_weather_text2font_cn "$WTD"`
        set_data_type "WFD" $WFD

        # high temperature
        HT=`echo "$dayinfo" | awk '{print $6}' | sed 's/^\(-\?[0-9]\+\).*$/\1/'`
        set_data_type "HT" $HT

        # wind direction text on day
        WDTD=`echo "$dayinfo" | awk '{print $7}'`
        set_data_type "WDTD" $WDTD

        # wind speed text on day
        WSTD=`echo "$dayinfo" | awk '{print $8}'`
        set_data_type "WSTD" $WSTD

        # weather info on night(maybe is disappeared)
        nightinfo=`echo "$day_weather_block" | awk -v RS='夜间' 'NR==2'`
        nightinfo=`echo "$nightinfo" | tr '\n' ' '` # skip newlines
        debug "  nightinfo#$daynum: $nightinfo"

        # weather text on night, if is a long text, it will append at
        # second line, and after parsing, it will appear as $8
        WTN=`echo "$nightinfo" | awk '{if ($8) print $2$7; else print $2}'`
        set_data_type "WTN" $WTN

        # weather font on night
        WFN=`general_weather_text2font_cn "$WTN"`
        set_data_type "WFN" $WFN

        # low temperature
        LT=`echo "$nightinfo" | awk '{print $4}' | sed 's/^\(-\?[0-9]\+\).*$/\1/'`
        set_data_type "LT" $LT

        # wind direction text on night
        WDTN=`echo "$nightinfo" | awk '{print $5}'`
        set_data_type "WDTN" $WDTN

        # wind speed text on night
        WSTN=`echo "$nightinfo" | awk '{print $6}'`
        set_data_type "WSTN" $WSTN

        write_data_types $daynum
    done
}

select_data_type_day_or_night ()  {
    # first, check the option "--night-mode"
    if [ "$night_mode" = "day" ]; then
        data_type=${data_type}D
    elif [ "$night_mode" = "night" ]; then
        data_type=${data_type}N
    elif [ "$night_mode" = "auto" ]; then
        if [ `is_night_now` ]; then
            data_type=${data_type}N
        else
            data_type=${data_type}D
        fi
    fi

    # second, ensure the selected data type existed, or toggle it
    value=`do_get_weather_data`
    if [ -z "$value" ]; then
        toggle_data_type_day_or_night
    fi
}

toggle_data_type_day_or_night () {
    debug "data_type[before toggle]: $data_type"
    case "$data_type" in
        *D) data_type=`echo "$data_type" | sed 's/D$/N/'`;;
        *N) data_type=`echo "$data_type" | sed 's/N$/D/'`;;
    esac
    debug "data_type[after toggle]: $data_type"
}

get_weather_data_hook () {
    hook_result=

    # relink data_type
    case "$data_type" in
        WF|WT|WDT|WST)
            select_data_type_day_or_night;;
    esac

    # result effect for special data types
    value=`do_get_weather_data`
    case "$data_type" in
        WFD|WFN)
            if [ "$night_mode" = "day" ]; then
                value=`wf_daymode "$value"`
            elif [ "$night_mode" = "night" ]; then
                value=`wf_nightmode "$value"`
            elif [ "$night_mode" = "auto" ]; then
                value=`wf_automode "$value"`
            fi
            hook_result="$value";;
    esac
}

parser_help () {
    cat <<EOF
Argument meaning:
    The complete url which page owns weather info you expect.
    [default: www.weather.com.cn/weather/101010100.shtml]
Support data types:
    WF:   weather font output, will link to WFD or WFN
          [effect by --night-mode]
    WFD:  weather font on day
    WFN:  weather font on night
    WT:   weather text, will link to WTD or WTN
          [effect by --night-mode]
    WTD:  weather text on day
    WTN:  weather text on night
    LT:   low temperature
          [default unit: celsius]
          [effect by --temp-unit]
    HT:   high temperature
          [default unit: celsius]
          [effect by --temp-unit]
    WDT:  wind direction text, will link to WDTD or WDTN
          [effect by --night-mode]
    WDTD: wind direction text on day
    WDTN: wind direction text on night
    WST:  wind speed text, will link to WSTD or WSTN
          [effect by --night-mode]
    WSTD: wind speed text on day
    WSTN: wind speed text on night
    LN:   location name
Support max future days: 6
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
# weather-cn.sh ends here
