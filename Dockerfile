# Build the latest openSUSE Tumbleweed image
FROM opensuse:tumbleweed

# the NON-OSS repo is not needed, save the network bandwidth and some time (~5 seconds) for each refresh
RUN zypper mr -d non-oss

# add the YaST repository - we need the Rubocop gem for libyui/libyui-rake
RUN zypper ar -f http://download.opensuse.org/repositories/YaST:/Head/openSUSE_Tumbleweed/ yast

# prefer the packages from the libyui devel project
RUN zypper ar -f -p 50 http://download.opensuse.org/repositories/devel:/libraries:/libyui/openSUSE_Tumbleweed/ libyui

# we need to install Ruby first to define the %{rb_default_ruby_abi} RPM macro
# see https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#run
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#/build-cache
# why we need "zypper clean -a" at the end
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
  ruby && zypper clean -a

RUN RUBY_VERSION=`rpm --eval '%{rb_default_ruby_abi}'` && \
  zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
  boost-devel \
  cmake \
  doxygen \
  fontconfig-devel \
  gcc-c++ \
  git \
  gtk3-devel \
  libyui-devel \
  libyui-gtk-devel \
  libyui-ncurses-devel \
  libyui-qt-devel \
  libzypp-devel \
  obs-service-source_validator \
  pkg-config \
  'pkgconfig(Qt5Core)' \
  'pkgconfig(Qt5Gui)' \
  'pkgconfig(Qt5Svg)' \
  'pkgconfig(Qt5Widgets)' \
  'pkgconfig(Qt5X11Extras)' \
  "rubygem($RUBY_VERSION:libyui-rake)" \
  "rubygem($RUBY_VERSION:rubocop)" \
  rpm-build \
  yast2-devtools \
  which \
  && zypper clean -a \
  && rm -rf /usr/lib64/ruby/gems/*/cache

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY libyui-travis /usr/local/bin

# run some smoke tests to make sure there is no serious issue with the image
RUN c++ --version

# this is a bit tricky as the libyui/rake loads some files at the initialization
RUN mkdir -p package && echo > package/test.spec && \
  echo -e 'SET(VERSION_MAJOR "42")\nSET(VERSION_MINOR "42")\nSET(VERSION_PATCH "42")' \
  > VERSION.cmake && rake -t -r libyui/rake -V && rm -rf package && rm VERSION.cmake
