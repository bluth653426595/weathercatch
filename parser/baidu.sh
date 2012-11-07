# baidu.sh ---
#
# Filename: baidu.sh
# Description: a parser fo weather_catcher
# Author: Xu FaSheng
# Created: 2012.11.06
# Version: 0.1
# Last-Updated:
#           By:
#     Update #: 0
# Keywords: weather_catcher parser
# Compatibility: weather_catcher_v0.1
#
#   May work on older versions but this is not guaranteed.
#

# This file is a part of weather_catcher

# Change Log:
# - 0.1
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


parser_name=baidu
debug parser_name: $parser_name


update_weather_data () {
    if [ ! $arg ]; then arg=tianqi; fi
    URL=http://www.baidu.com/s?wd=$arg
    debug URL: $URL
    w3m -dump $URL>$weather_tmp_file
}

parser_help () {
    cat <<EOF
TODO
future_day_0 () {
WF=a
}
EOF
}

parser_version () {
    echo 0.1
}

debug parser load success


#
# baidu.sh ends here
