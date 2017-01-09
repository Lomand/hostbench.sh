#!/bin/bash
echo "Initiating benchmark..."

# Benchmark requires root privileges to be able to build packages from source and install them into the system.

if [ "$(whoami)" != "root" ]; then
printf "You must run this script as root user.\n"
exit 1
elif test "$#" -ne 1; then
printf "You should provide ID to run the benchmark.\nExample: sudo ./benchmark.sh 'IRMMTUI71YYCZ'\n"
exit 1
else
printf "\033c"
echo "Installing benchmark dependencies...."

# Everything is Ok, now we can start...
OS=$(echo `awk -F= '/^ID_LIKE/{print $2}' /etc/os-release`)
ID=$(echo `awk -F= '/^ID=/{print $2}' /etc/os-release`)
INSTALL=()

# Ubuntu
if [ "$OS" =  "debian" ]; then

ESSENTIALS=(build-essential libaio-dev zlib1g-dev libncurses5-dev gcc make automake autopoint pkg-config curl  checkinstall unzip libtool bc git virt-what)

for package in "${ESSENTIALS[@]}"; do
            if [ $(dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  INSTALL+=($package)
fi
  done
apt-get update
apt-get install -y ${INSTALL[@]} --fix-missing

ARIA2=aria2c
FIO=fio
SYSBENCH=sysbench


# Debian
elif [ "$ID" =  "debian" ]; then

ESSENTIALS=( build-essential libaio-dev zlib1g-dev libncurses5-dev gcc make automake autopoint pkg-config curl  checkinstall unzip libtool bc git virt-what)

for package in "${ESSENTIALS[@]}"; do
            if [ $(dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  INSTALL+=($package)
fi
  done

apt-get update
apt-get install -y ${INSTALL[@]} --fix-missing


# Creating dirs for compiling packages...
mkdir /root/tmp
mkdir /usr/local/share/doc
mkdir /usr/local/man
mkdir /usr/local/share/man/ru
mkdir /usr/local/share/man/pt
mkdir /usr/local/share/doc/aria2

ARIA2=aria2c
FIO=fio
SYSBENCH=sysbench


# Centos 7
elif [ "$OS" =  '"rhel fedora"' ]; then

ESSENTIALS=(rpm-build  gcc gcc-c++ make openssl-devel libaio-devel  zlib-devel ncurses-devel  automake gettext-devel pkgconfig curl unzip rpmdevtools libtool bc git virt-what wget bind-utils)
for package in "${ESSENTIALS[@]}"; do

if yum list installed "$package" >/dev/null 2>&1; then
    echo $package 'is already installed. Moving on...'
  else
    INSTALL+=($package)
  fi
  done
yum makecache fast
yum install -y   ${INSTALL[@]}

rpmdev-setuptree
# Checkinstall is not available in the standart centos repository, so we manually downloading  and installing it. 
wget ftp://ftp.pbone.net/mirror/distrib-coffee.ipsl.jussieu.fr/mageia/distrib/4/x86_64/media/core/release/checkinstall-1.6.2.16-9.mga4.x86_64.rpm

yum install -y checkinstall-1.6.2.16-9.mga4.x86_64.rpm

# Creating dirs for compiling packages...
mkdir /root/tmp
mkdir /usr/local/share/doc
mkdir /usr/local/man
mkdir /usr/local/share/man/ru
mkdir /usr/local/share/man/pt
mkdir /usr/local/share/doc/aria2


ARIA2=/usr/local/bin/aria2c
FIO=/usr/local/bin/fio
SYSBENCH=/usr/local/bin/sysbench

else
printf "Sorry, your OS is not supported, therefore, you cant execute this benchmark. Hostbench is compatible with Ubuntu 16.04, 14.04 and Centos 7.\n"
exit 1
fi

# Function for 5 second delay between benchmarks
empty_line()
{
  sleep 5
  echo -e ""
}

printf "\033c"
echo "Building benchmark components from source code...."
echo "This step will take from 10 to 15 minutes. Please, be patient."
empty_line
cd /tmp
git clone https://github.com/Lomand/hostbench.sh.git
cd hostbench.sh
# Installing Sysbench...
unzip sysbench-1.0.zip
cd sysbench-1.0
./autogen.sh
./configure --without-mysql
make
checkinstall  -y --install=yes
cd ..
# Installing Fio...
unzip fio-master.zip 
cd fio-master
./configure
make
checkinstall   -y --pkgversion="213" --install=yes
cd ..
# Installing Aria2...
unzip aria2-master.zip
cd aria2-master
autoreconf -i
./configure --without-libxml2 --without-wintls --without-appletls --disable-bittorrent --disable-metalink
make
checkinstall   -y --pkgversion="126" --install=yes
cd ..

CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
RAM=$(cat /proc/meminfo | grep MemTotal | awk '{ size=sprintf("%.0f", $2/1024); print size }')

QUAD="1500M"  
TEN=$((RAM*10))"M"
COUNTER=0
SERVER=("AMS" "CHE" "DAL"  "FRA" "HKG" "LON" "MEL" "MIL" "MON" "PAR" "MEX" "SJC" "SAO" "SEA" "SNG" "SYD" "SEO" "TOK" "TOR" "WDC")


# Function to display a string on the center of the console
center()
{
  w=$(stty size | cut -d" " -f2)
  l=${#1}
  printf "%"$((l+(w-l)/2))"s\n" "$1 "
}
# Function to get the speed from FIO in Kb/s
getKBS() {
  grep 'aggrb=' | awk  '{if( $3 ~ /MB/) print substr($3,7,4)*1024; else print  substr($3, 7, length($3)-11)}'
}

# Clearing the console...
printf "\033c"
center " _   _           _   _                     _       _       "
center "| | | |         | | | |                   | |     (_)      "
center "| |_| | ___  ___| |_| |__   ___ _ __   ___| |__    _  ___  "
center "|  _  |/ _ \/ __| __| '_ \ / _ \ '_ \ / __| '_ \  | |/ _ \ "
center "| | | | (_) \__ \ |_| |_) |  __/ | | | (__| | | |_| | (_) |"
center "\_| |_/\___/|___/\__|_.__/ \___|_| |_|\___|_| |_(_)_|\___/ "
center "RC3"
center "The benchmark usually takes about 30 minutes to be completed, but in some cases, it could last for an hour."
center "For the reliable results, run this script only on new VPS."
center "WARNING: During the benchmark you will write to the disk about 5GB and download about 10GB of data."
center "Hostbench.io accepts no responsibility for any additional costs or damage this script may cause."
center "The script has been tested on Ubuntu 16.04, 14.04, Debian 6, 7 and Centos 7. Proper execution on different OS'es is not guaranteed."
empty_line
echo "Starting Benchmark..."
echo "UID: $1" >> benchmark.results

echo "ServerIP: `dig +short myip.opendns.com @resolver1.opendns.com`" >> benchmark.results
echo "Getting distro information and disk size..."
echo "Distro: `awk -F= '/^PRETTY_NAME/{print $2}' /etc/os-release`" | tee -a benchmark.results
echo "DiskSize: `df | grep '^/' | awk '{s+=$2} END {size=sprintf("%.0f", s/1048576);print size}'`" | tee -a benchmark.results | awk '{print $1 " " $2 " GB"}'
echo "RAMSize: $RAM" | tee -a benchmark.results | awk '{print $1 " " $2 " MB"}'
echo "Checking CPU specs..."
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
echo """CPU(s): `echo `$CORES`` """| tee -a benchmark.results
echo "`cat /proc/cpuinfo | grep 'model name' |awk 'NR==1{print $0}'`"  | tee -a benchmark.results 
echo "`cat /proc/cpuinfo | grep 'cpu MHz' | awk 'NR==1{print $0}'`"  | tee -a benchmark.results 
echo "`cat /proc/cpuinfo | grep 'cache size' | awk 'NR==1{print $0}'`"  | tee -a benchmark.results 
echo "Virtualization: `virt-what`"  | tee -a benchmark.results 
empty_line
echo "Benchmarking CPU..."
CPUBenchTime="`$SYSBENCH --test=cpu --cpu-max-prime=24576 --num-threads=$CORES run | grep 'total time': | awk '{ print $3}'|grep -oE '[0-9]+([.][0-9]+)?'`"
echo """CPUScore: `echo "(24576/$CPUBenchTime)*3.4" | bc`""" | tee -a benchmark.results | awk '{print $1 " " $2 " points"}'
empty_line
echo "Benchmarking RAM bandwith..."
echo "RAMBandwith: `$SYSBENCH --test=memory --memory-total-size=$TEN run | grep 'transferred (' | awk '{ print substr($4,2);}'`" | tee -a benchmark.results | awk '{print $1 " " $2-2 " MB/s"}'
empty_line
echo "Benchmarking Write Speed  and IOPS of 4K blocks..."
echo "`$FIO --randrepeat=1 --ioengine=libaio --direct=1 --name=io.benchmark --filename=io.benchmark --bs=4k  --size=$QUAD --readwrite=randwrite |grep -E 'write: io='| awk -F',' '{gsub(" ",""); gsub("iops=","\nWIOPS:"); gsub("bw=","Write4K:"); gsub("KB/s",""); print  $2  $3}'`" | tee -a benchmark.results  | awk 'NR==1 { print $0 " KB/s" } END  { print $0 " IOPS" }' 
empty_line
echo "Benchmarking Write Speed of 64K blocks..."
echo "Write64K: `$FIO --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=io.benchmark --filename=io.benchmark --bs=64k  --size=$QUAD --readwrite=randwrite | getKBS`" | tee -a benchmark.results | awk '{print $1 " " $2/1024 " MB/s"}'
empty_line
echo "Benchmarking Write Speed of 512K blocks..."
echo "Write512K: `$FIO --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=io.benchmark --filename=io.benchmark --bs=512k  --size=$QUAD --readwrite=randwrite | getKBS`" | tee -a benchmark.results | awk '{print $1 " " $2/1024 " MB/s"}'
empty_line
echo "Benchmarking Read Speed and IOPS of 4K blocks..."
echo "`$FIO --randrepeat=1 --ioengine=libaio --direct=1 --name=io.benchmark --filename=io.benchmark --bs=4k  --size=$QUAD --readwrite=randread |grep -E 'read : io='| awk -F',' '{gsub(" ",""); gsub("iops=","\nRIOPS:"); gsub("bw=","Read4K:"); gsub("KB/s",""); print  $2  $3}'`" | tee -a benchmark.results | awk 'NR==1 { print $0 " KB/s" } END { print $0 " IOPS" }' 
empty_line
echo "Benchmarking Read Speed of 64K blocks..."
echo "Read64K: `$FIO --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=io.benchmark --filename=io.benchmark --bs=64k  --size=$QUAD --readwrite=randread  | getKBS`" | tee -a benchmark.results | awk '{print $1 " " $2/1024 " MB/s"}'
empty_line
echo "Benchmarking Read Speed of 512K blocks..."
echo "Read512K: `$FIO --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=io.benchmark --filename=io.benchmark --bs=512k  --size=$QUAD --readwrite=randread  | getKBS`" | tee -a benchmark.results | awk '{print $1 " " $2/1024 " MB/s"}'

# Function for bandwith benchmark, result is in Mib/s

bandwith_benchmark() {
  SERVER_HOST=`echo "${2:7:${#2}-29}"`
  PING=`ping -qc 5 $SERVER_HOST | awk -F/ '/^rtt/ {print $5}'`
  empty_line
  echo "[ $((COUNTER+1))/ ${#SERVER[@]}] Testing download speed from $1 (Ping: $PING ms)"
  
  DOWNLOAD_SPEED=`$ARIA2 -d /dev -o null  --allow-overwrite=true -x 5 $2  --file-allocation=none | grep 'MiB/s\|KiB/s' |  awk '{print $3}' | cut -f1 -d"|"`
  echo "$DOWNLOAD_SPEED"

  if [  "${DOWNLOAD_SPEED: -5}" == "KiB/s" ]
  then
  MEGABYTE=`echo " ${DOWNLOAD_SPEED::-5} * 0.001 " | bc`
echo "${SERVER[COUNTER]}: $MEGABYTE"    >> benchmark.results
else
echo "${SERVER[COUNTER]}: ${DOWNLOAD_SPEED::-5}  " >> benchmark.results
fi
  echo "${SERVER[COUNTER]}ping: $PING" >> benchmark.results
  COUNTER=$((COUNTER+1))
}
empty_line
echo "Benchmarking maximum throughput between server and single user in different location..."
echo "(Keep in mind that this is not equivalent to maximum download speed of the server.)"
bandwith_benchmark 'Amsterdam, The Netherlands' 'http://speedtest.ams01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Chennai, India' 'http://speedtest.che01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Dallas, USA' 'http://speedtest.dal01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Frankfurt, Germany' 'http://speedtest.fra02.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Hong Kong, China' 'http://speedtest.hkg02.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'London, England' 'http://speedtest.lon02.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Melbourne, Australia' 'http://speedtest.mel01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Milan, Italy' 'http://speedtest.mil01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Montreal, Canada' 'http://speedtest.mon01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Paris, France' 'http://speedtest.par01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Queretaro, Mexico' 'http://speedtest.mex01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'San Jose, USA' 'http://speedtest.sjc01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Sao Paulo, Brazil' 'http://speedtest.sao01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Seattle, USA' 'http://speedtest.sea01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Singapore, Singapore' 'http://speedtest.sng01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Sydney, Australia' 'http://speedtest.syd01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Seoul, Korea' 'http://speedtest.seo01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Tokyo, Japan' 'http://speedtest.tok02.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Toronto, Canada' 'http://speedtest.tor01.softlayer.com/downloads/test500.zip'
bandwith_benchmark 'Washington, D.C., USA' 'http://speedtest.wdc01.softlayer.com/downloads/test500.zip'

echo "Uploading results to hostbench.io..."

empty_line
curl --form "fileupload=@benchmark.results" https://submit.hostbench.io
cp benchmark.results  ~/benchmark.results
empty_line
empty_line

echo "You can find a copy of the benchmark in your home directory (~)."

echo "Removing benchmark components..."

if [ "$OS" =  "debian" ] || [ "$ID" =  "debian" ]; then

dpkg -r aria2 fio sysbench >/dev/null 2>&1

apt-get remove -y ${INSTALL[@]} >/dev/null 2>&1
apt-get autoremove -y >/dev/null 2>&1

elif [ "$OS" =  '"rhel fedora"' ]; then

rpm -e fio-213-1  sysbench-1.0-1 aria2-126-1 >/dev/null 2>&1

INSTALL+=(checkinstall)
yum remove -y   ${INSTALL[@]} >/dev/null 2>&1
yum autoremove -y >/dev/null 2>&1
fi

rm -r /tmp/hostbench.sh
echo "Thank you for submitting your benchmark."
fi
