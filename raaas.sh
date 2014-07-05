apt-get install -y gfortran build-essential make gcc build-essential git-core curl wget vim-tiny nano

apt-get install -y python2.7 python2.7-dev
wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py; python get-pip.py; rm -f /get-pip.py
apt-get install -y python-imaging libpng-dev libfreetype6 libfreetype6-dev

apt-get install libblas3gf libblas-doc libblas-dev
apt-get install liblapack3gf liblapack-doc liblapack-dev

apt-get install -y python-numpy python-setuptools
easy_install pytz
apt-get install -y python-numpy rabbitmq-server