#!/bin/sh

# weathercatch.sh ---
#
# Filename: weathercatch.sh
# Description: a simple tool to get weather info in the web page through parsing the content
# Author: Xu FaSheng
# Created: 2012.11.05
# Keywords: weather web parse
#

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

help () {
    cat <<EOF
Description:
    weathercatch is a simple tool to get weather info in the web page through parsing the content.

Usage:
    weathercatch.sh [-p parser] [-a argument] [-d datatype] [-n nightmode] [-f futureday] [-t tempunit] [-l] [-D] [-h] [-v]

Options:
    -p, --parser=[PARSER]
        The built-in parser could be:
          google
          baidu
          weather-cn
        And you could use a custom parser, just transmit the
        script file path here.
        [default: $default_parser]
    -a, --argument=[ARGUMENT]
        The argument has different meaning for each parser,
        you should have a look at its help message.
        And the arguments's meaning for built-in parsers could be:
          google         the keyword to search which results will own
                         weather info you expect, in fact, it just
                         could be "weather cityname".
          baidu:         the keyword to search which results will
                         own weather info you expect, in fact, it
                         just could be a city name
          weather-cn:    the complete url which page owns weather
                         info you expect
        [default: different for each parser]
    -d, --data-type=[DATATYPE]
        The built-in data type could be:
          WF:  weather font output
               [effect by --night-mode]
          WT:  weather text
          LT:  low temperature
               [default unit: celsius]
               [effect by --temp-unit]
          HT:  high temperature
               [default unit: celsius]
               [effect by --temp-unit]
          CT:  current temperature
               [default unit: celsius]
               [effect by --temp-unit]
          WD:  wind direction
          WDT: wind direction text
          WS:  wind speed
               [default unit: kmh]
          WST: wind speed text
          HM:  humidity
               [default unit: percent]
          LN:  location name
          ALL: all support data types
        Note: the supported data types is different for each parser,
              you'd better have a look at the parser's help message.
        [default: ALL]
    -n, --night-mode=[NIGHTMODE]
        Will effect some data type's value, such as WF.
        The night mode could be:
          day, night, auto
        [default: auto]
    -f, --future-day=[NUM]
        Get weather info in the future NUM day,
        for example, 0 means today, 1 means tomorrow.
        Note: not all the parser support this options.
        [default: 0]
    -t, --temp-unit=[TEMPUNIT]
        Set the temperature unit, effect for data type HT, LT and CT,
        The temperature unit could be:
          c, celsius
          f, fahrenheit
        [default: c]
    -l, --use-last-data
        Use last weather data if possible.
    -D, --debug
        Use debug mode, for testing.
    -h, --help
        Prints main or parser's help message and exits.
    -v, --version
        Prints main or parser's version information and exits.

Depends:
    w3m, most parsers will use it
    coretuils v7.0+, for the 'timeout' command, not necessary

Examples:
    - print help message
      weathercatch.sh -h
    - print version and built-in parsers
      weathercatch.sh -v
    - print a parser's help message
      weathercatch.sh -p google -h
    - print all weather info today
      weathercatch.sh
      weathercatch.sh -p google -a "weather new york" -d ALL
    - print tomorrow's weather text
      weathercatch.sh -d WT -f 1
    - print weather font, use night mode
      weathercatch.sh -d WF -n night
    - use a custom parser
      weathercatch.sh -p your_parser.sh -a argument

EOF
    exit 1
}

version () {
    echo "version 0.3"
    echo "built-in parsers:"
    for p in ./parser/*.sh; do
        debug $p
        source $p
        printf "  %s: %s\n" "$parser_name" "`parser_version`"
    done
    exit 1
}

debug () {
    if [ $debug ]; then
        echo "[D] " $debug_prefix "$@"
    fi
}

debug_lines () {
    IFS=''
    debug "$1"
    while read line; do
        debug " " "$line"
    done <<< "$2"
}

get_parser_script () {
    builtin_parser="./parser/$1.sh"
    if [ -z "$1" ]; then
        # default parser
        echo "./parser/${default_parser}.sh"
    elif [[ -f "$builtin_parser" && -s "$builtin_parser" ]]; then
        # built-in parser
        echo "$builtin_parser"
    else
        # custom parser
        echo "$1"
    fi
}

## global variables
weather_data_file="/tmp/weathercatch.txt"
weather_tmp_file="/tmp/weathercatch.tmp"
default_parser="google-hk"

## dispatch options
parser=
arg=
data_type=ALL
night_mode=auto
future_day=0
temp_unit=c
use_last_data=
debug=
help=
version=

if ! options=$(getopt -o p:a:d:n:f:t:lDhv -l parser:,argument:,data-type:,night-mode:,future-day:,temp-unit:,use-last-data,debug,help,version -- "$@")
then
    # something went wrong, getopt will put out an error message for us
    exit 1
fi

eval set -- "$options"
while [ $# -gt 0 ]
do
    case $1 in
        -p|--parser)        parser="$2"; shift;;
        -a|--argument)      arg="$2"; shift;;
        -d|--data-type)     data_type="$2"; shift;;
        -n|--night-mode)    night_mode="$2"; shift;;
        -f|--future-day)    future_day="$2"; shift;;
        -t|--temp-unit)     temp_unit="$2"; shift;;
        -l|--use-last-data) use_last_data=t;;
        -D|--debug)         debug=t;;
        -h|--help)          help=t;;
        -v|--version)       version=t;;
        --)                 shift; break ;;
        *)                  break ;;
    esac
    shift
done

# select parser
parser_script=`get_parser_script "$parser"`

# show help message
if [ "$help" ]; then
    if [ "$parser" ]; then
        source "$parser_script"
        parser_help
        exit
    else
        help
    fi
fi
if [ "$version" ]; then
    if [ "$parser" ]; then
        source "$parser_script"
        parser_version
        exit
    else
        version
    fi
fi

## assistant functions
source "./functions.sh"

## variable and function should be redefined in parser
parser_name=
update_weather_data () {
    # the main function for parser, which will get weather info
    # from remote server, then parse it, and put the data into
    # $weather_data_file in a format shows following:
    # future_day_0 () {
    #     WF=a
    #     WT="Sunny"
    #     ...
    # }
    # future_day_1 () {
    #     ...
    # }
    echo "warnning, function need to be redefined"
}
get_weather_data_hook () {
    # if the parser want to operate some special data type, could
    # redefine this function, and change the variable $hook_result,
    # then function 'get_weather_data' will use the output content
    # instead its, and maybe will use the global variable $data_type
    # here.
    hook_result=
}
parser_help () {
    echo "warnning, function need to be redefined"
}
parser_version () {
    echo "warnning, function need to be redefined"
}

## main content
source "$parser_script"

if [[ -f "$weather_data_file" && -s "$weather_data_file" ]]; then
    if [ ! "$use_last_data" ]; then
        update_weather_data
    fi
else
    update_weather_data
fi

get_weather_data
