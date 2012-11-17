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

prefix=/usr
bindir=$(prefix)/bin
appname=weather_catcher
installdir=$(prefix)/share
appdir=$(installdir)/$(appname)
mainfiles=weather_catcher.sh functions.sh \
          Makefile README COPYING Changelog example_conky_rc
parserfolder=parser

# use real_prefix for creating package for some linux distribution, such as AUR(Arch User Repository)
real_prefix=$(prefix)
real_appdir=$(real_prefix)/share/$(appname)

.PHONY : help example-conky install uninstall

help :
	@echo "make [install|uninstall|example|example-conky|help] [installdir=$(installdir)]"

example-google :
	sh ./weather_catcher.sh -p google -a "weather new york" -d ALL
example-google-hk :
	sh ./weather_catcher.sh -p google-hk -a "weather hongkong" -d ALL
example-baidu :
	sh ./weather_catcher.sh -p baidu -a weather -d ALL
example-weather-cn :
	sh ./weather_catcher.sh -p weather-cn -a www.weather.com.cn/weather/101010100.shtml -d ALL

example-conky :
	conky -c example_conky_rc

install :
	@echo "==> install..."
	@echo "==> copy files"
	-mkdir $(appdir)
	@for f in $(mainfiles); do \
	  cp -vf $${f} $(appdir); \
	done
	@cp -rvf $(parserfolder) $(appdir)
	@echo "==> create runner"
	@echo '#!/bin/sh' > $(bindir)/weather_catcher
	@echo 'cd $(real_appdir);sh ./weather_catcher.sh "$$@"' >> $(bindir)/weather_catcher
	chmod +x $(bindir)/weather_catcher
	@echo '#!/bin/sh' > $(bindir)/weather_catcher_conky_example
	@echo 'cd $(real_appdir);conky -c ./example_conky_rc' >> $(bindir)/weather_catcher_conky_example
	chmod +x $(bindir)/weather_catcher_conky_example
	@echo "==> done."

uninstall :
	@echo "==> uninstall..."
	@echo "==> delete data files"
	@rm -rvf $(appdir)
	@echo "==> delete runner"
	@rm -vf $(bindir)/weather_catcher
	@rm -vf $(bindir)/weather_catcher_conky_example
	@echo done.

######################################################################
### Makefile ends here
