## description

weather_catcher is a simple tool to get weather info in the web page
through parsing the content, and it have several built-in weather parsers,
inculde google, baidu, etc.

## usage

    weather_catcher.sh [-p parser] [-a argument] [-d datatype] [-n nightmode]
                       [-f futureday] [-t tempunit] [-l] [-D] [-h] [-v]

## examples

- **print help message**

        weather_catcher.sh -h

- **print version and built-in parsers**

        weather_catcher.sh -v

- **print a parser's help message**

        weather_catcher.sh -p google -h

- **print all weather info today**

        weather_catcher.sh
        weather_catcher.sh -p google -a "weather new york" -d ALL

- **print tomorrow's weather text**

        weather_catcher.sh -d WT -f 1

- **print weather font, use night mode**

        weather_catcher.sh -d WF -n night

- **use a custom parser**

        weather_catcher.sh -p builtin_parser_name -a argument
        weather_catcher.sh -p your_parser.sh -a argument

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
- **/usr/bin/weather\_catcher**

  a wrapper to run the main script weather_catcher.sh

- **/usr/bin/weather\_catcher\_conky\_example**

  just for showing the conky example
