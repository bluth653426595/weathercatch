#!/bin/sh

# weather_catcher.sh ---
#
# Filename: weather_catcher.sh
# Description: a simple tool to get weather info in the web page through parsing the content
# Author: Xu FaSheng
# Created: 2012.11.05
# Version: 0.1
# Last-Updated:
#           By:
#     Update #: 0
# URL:
# Keywords: weather web parse
#

# This file is a part of weather_catcher

# Change Log:
# - 0.1
#   + create
#
#
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
    weather_catcher is a simple tool to get weather info in the web page through parsing the content.

Usage:
    weather_catcher.sh [-p parser] [-a argument] [-d datatype] [-n nightmode] [-f futuredays] [-l] [-D] [-h] [-v]

Options:
    -p, --parser=[PARSER]
        The builtin parser could be:
          baidu
          weather-cn
          yahoo-weather
        And you could use a custom parser, just transmit the
        script file path here.
        [default: baidu]
    -a, --argument=[ARGUMENT]
        The argument has different meaning for each parser,
        you should have a look at its help message.
        And the arguments's meaning for builtin parsers could be:
          baidu:         the keyword to search which results will
                         own weather info you expect, in fact, it
                         just could be a city name
          weather-cn:    the complete url which page owns weather
                         info you expect
          yahoo-weather: the complete url which page owns weather
                         info you expect
        [default: different for each parser]
    -d, --data-type=[DATATYPE]
        The builtin data type could be:
          WF:  weather font output
          WT:  weather text
          LT:  low temperature
          HT:  high temperature
          CT:  current temperature
          WD:  wind direction
          WS:  wind speed
          HM:  humidity
          LN:  location name
          ALL: all support data types
        Note: the supported data types is different for each parser,
              you'd better have a look at the parser's help message.
        [default: WT, maybe different for each parser]
    -n, --night-mode=[NIGHTMODE]
        Will effect some data type's value, such as WF.
        The night mode could be:
          day, night, auto
        [default: auto]
    -f, --future=[NUM]
        Get weather info in the future NUM days,
        for example, 0 means today, 1 means tomorrow.
        Note: not all the parser support this options.
        [default: 0]
    -l, --use-last-data
        Use last weather info.
    -D, --debug
        Use debug mode, for testing.
    -h, --help
        Prints main or parser's help message and exits.
    -v, --version
        Prints main or parser's version information and exits.

EOF
    exit 1
}

version () {
    echo 0.1
    exit 1
}

## assistant functions
source ./functions.sh

## variable and function should be redefined in parser
parser_name=
get_weather_info () {
    URL=http://www.baidu.com/s?wd=$1
    w3m -dump $URL>$weather_data_file
}
# parser_help () {
# }
# parser_version () {
# }

## global variables
weather_data_file=/tmp/weather_catcher.txt
weather_tmp_file=/tmp/weather_catcher.tmp

## dispatch options
parser=
argument=
data_type=
use_last_data=
debug=

# TODO
parser_baidu=./parser/baidu.sh
source $parser_baidu

# TODO
echo $parser_name

## main content

if [[ -f $weather_data_file && -s $weather_data_file ]]; then
    echo exits
else
    get_weather_info
fi


# TODO
usage
# version

#
# weather_catcher.sh ends here
        # the meaning for builtin parser could be:
        #   baidu:         the keyword to search which results will
        #                  own weather info you expect, in fact, it
        #                  just could be a city name
        #   weather-cn:    the complete url which page owns weather
        #                  info you expect
        #   yahoo-weather: the complete url which page owns weather
        #                  info you expect
        # And if you use a custom parser, you should try to understand
        # its argument's meaning by reading the document.
