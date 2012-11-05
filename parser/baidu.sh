parser_name=baidu

get_weather_info () {
    URL=http://www.baidu.com/s?wd=$1
    w3m -dump $URL>$weather_data_file
}
