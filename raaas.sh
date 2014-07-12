apt-get install -y gfortran build-essential make gcc build-essential git-core curl wget vim-tiny nano

apt-get install libblas3gf libblas-doc libblas-dev
apt-get install liblapack3gf liblapack-doc liblapack-dev
apt-get install docker.io

apt-get install -y python2.7 python2.7-dev
wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py; python get-pip.py; rm -f /get-pip.py
apt-get install -y python-imaging libpng-dev libfreetype6 libfreetype6-dev

apt-get install -y python-setuptools rabbitmq-server
easy_install pytz
pip install cython simplejson tornado celery

sudo mkdir /opt/raas
sudo chown -R asl:asl /opt/raas
mkdir /opt/raas/code
mkdir /opt/raas/datasets

git clone --branch dibyo https://github.com /rll/raas.git /opt/raas/repo
sudo tee -a /etc/bash.bashrc <<EOF

# RAaaS path
export PYTHONPATH=$PYTHONPATH:/opt/raas/repo/src:/opt/raas/repo/src/raas_example
EOF

ln -s /opt/raas/repo/scripts /opt/raas/code/bin
ln -s /opt/raas/repo/src /opt/raas/code/src

sudo apt-get -y install autoconf automake libass-dev libfreetype6-dev libgpac-dev \
  libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libx11-dev \
  libxext-dev libxfixes-dev pkg-config texi2html zlib1g-dev
mkdir ~/ffmpeg_sources


sudo apt-get install yasm
sudo apt-get install libmp3lame-dev
sudo apt-get install libopus-dev
sudo apt-get install unzip

cd ~/ffmpeg_sources
wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
tar xjvf last_x264.tar.bz2
cd x264-snapshot*
PATH="$PATH:$HOME/bin" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static
PATH="$PATH:$HOME/bin" make
make install
make distclean

cd ~/ffmpeg_sources
wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master
unzip fdk-aac.zip
cd mstorsjo-fdk-aac*
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install
make distclean

cd ~/ffmpeg_sources
wget http://webm.googlecode.com/files/libvpx-v1.3.0.tar.bz2
tar xjvf libvpx-v1.3.0.tar.bz2
cd libvpx-v1.3.0
./configure --prefix="$HOME/ffmpeg_build" --disable-examples
make
make install
make clean

cd ~/ffmpeg_sources
wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
PATH="$PATH:$HOME/bin" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --bindir="$HOME/bin" \
  --extra-libs="-ldl" \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-nonfree \
  --enable-x11grab
PATH="$PATH:$HOME/bin" make
make install
make distclean
hash -r

git clone https://github.com/jayrambhia/Install-OpenCV.git ~/Install-OpenCV
cd ~/Install-OpenCV/Ubuntu/
sed -i 's/^sudo apt-get -qq remove ffmpeg x264 libx264-dev/# sudo apt-get -qq remove ffmpeg x264 libx264-dev/' dependencies.sh
sed -i 's/^install_dependency ffmpeg/# sinstall_dependency ffmpeg/' dependencies.sh

./opencv_latest.sh

# Installing Docker
sudo apt-get install -y docker.io
sudo ln -sf /usr/bin/docker.io /usr/local/bin/docker
sudo sed -i '$acomplete -F _docker docker' /etc/bash_completion.d/docker.io