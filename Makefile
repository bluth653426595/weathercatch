### Makefile ---
##
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation; either version 3, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, write to
## the Free Software Foundation, Inc., 51 Franklin Street, Fifth
## Floor, Boston, MA 02110-1301, USA.
##
######################################################################
##
### Code:

prefix=/usr/share
bindir=/usr/bin
appname=weather_catcher
appdir=$(prefix)/$(appname)
mainfiles=weather_catcher.sh functions.sh \
          Makefile README COPYING example_conky_rc
parserfiles=parser/baidu.sh parser/weather-cn.sh

.PHONY : help test test-conky install uninstall

help :
	@echo "make [install|uninstall|test|test-conky|help] [prefix=$(prefix)]"

test :
	sh ./weather_catcher.sh -p baidu -a weather -d ALL
	sh ./weather_catcher.sh -p weather-cn -a www.weather.com.cn/weather/101010100.shtml -d ALL

test-conky :
	conky -c example_conky_rc

install :
	@echo "==> install..."
	@echo "==> copy files"
	-mkdir $(appdir)
	-@for f in $(mainfiles); do \
	  cp -vf $${f} $(appdir); \
	done
	-mkdir $(appdir)/parser
	-@for f in $(parserfiles); do \
	  cp -vf $${f} $(appdir)/parser; \
	done
	@echo "==> create runner"
	@echo '#!/bin/sh' > $(bindir)/weather_catcher
	@echo 'cd $(appdir);sh ./weather_catcher.sh "$$@"' >> $(bindir)/weather_catcher
	chmod +x $(bindir)/weather_catcher
	@echo '#!/bin/sh' > $(bindir)/weather_catcher_conky_example
	@echo 'cd $(appdir);conky -c ./example_conky_rc' >> $(bindir)/weather_catcher_conky_example
	chmod +x $(bindir)/weather_catcher_conky_example
	@echo "==> done."

uninstall :
	@echo "==> uninstall..."
	@echo "==> delete data files"
	-@for f in $(parserfiles); do \
	  rm -vf $(appdir)/$${f}; \
	done
	-rmdir $(appdir)/parser
	-@for f in $(mainfiles); do \
	  rm -vf $(appdir)/$${f}; \
	done
	-rmdir $(appdir)
	@echo "==> delete runner"
	rm -f $(bindir)/weather_catcher
	rm -f $(bindir)/weather_catcher_conky_example
	@echo done.

######################################################################
### Makefile ends here
