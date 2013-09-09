## description

weathercatch is a simple tool to get weather info in the web page
through parsing the content, and it have several built-in weather parsers,
inculde google, baidu, etc.

## usage

    weathercatch [-p parser] [-a argument] [-d datatype] [-n nightmode]
                    [-f futureday] [-t tempunit] [-l] [-D] [-h] [-v]

## examples

- **print help message**

        weathercatch -h

- **list built-in parsers and versions**

        weathercatch -v

- **print a parser's help message**

        weathercatch -p google -h
        weathercatch -p google-hk -h
        weathercatch -p baidu -h
        weathercatch -p weather-cn -h

- **print all weather info today**

        weathercatch
        weathercatch -p google -a "weather new york" -d ALL
        weathercatch -p baidu -a "天气" -d ALL
        weathercatch -p weather-cn -a "http://www.weather.com.cn/html/weather/101200101.shtml" -d ALL

  the output maybe like this:
        LN=武汉
        WTD=多云
        WFD=d
        HT=31
        WDTD=无持续风向
        WSTD=微风
        WTN=中雨
        WFN=h
        LT=23
        WDTN=无持续风向
        WSTN=微风

- **print tomorrow weather's text**

        weathercatch -d WT -f 1

- **print weather font code, use night mode**

        weathercatch -d WF -n night

- **use a custom parser**

        weathercatch -p builtin_parser_name -a argument
        weathercatch -p your_parser.sh -a argument

## screenshot by conky

&nbsp;&nbsp;![conky_example_weather_cn](img/conky_example_weather_cn.png "Parse !weather-cn")
&nbsp;&nbsp;![conky_example_google_hk](img/conky_example_google_hk.png "Parse !google-hk")
&nbsp;&nbsp;![conky_example_google](img/conky_example_google.png "Parse google")

## install and uninstall

- **depends**
  - w3m, most parsers will use it
  - coretuils v7.0+, for the 'timeout' command, not necessary
- **test before install**

        make example-google
        make example-google-hk
        make example-baidu
        make example-conky

- **install**

        ./configure
        make install

- **uninstall**

        make uninstall

## binary files
- **/usr/bin/weathercatch**

  a wrapper to run the main script weathercatch.sh

- **/usr/bin/weathercatch\_conky\_example**

  just for showing the conky example
