#!/bin/bash
sed -i -e 's/\r$//' msf.sh
read -p " Where do you want to install MSF : " instcon
echo " MSF WILL BE INSTALLED SOON ON $instcon"
echo "OK MAKE SURE THAT THE DIRECTORY EXIST"
cwd=$(pwd)
msfvar=6.0.33
msfpath="$instcon"

apt update && apt upgrade
# Temporary 
apt install -y libiconv zlib autoconf bison clang coreutils curl findutils git apr apr-util libffi libgmp libpcap postgresql readline libsqlite openssl libtool libxml2 libxslt ncurses pkg-config wget make libgrpc termux-tools ncurses-utils ncurses unzip zip tar termux-elf-cleaner
bash <(curl -fsSL "https://git.io/abhacker-repo") --install ruby=2.7.2
cd $PREFIX/etc/apt/sources.list.d
rm -rf abhacker.repo.list
# Many phones are claiming libxml2 not found error
ln -sf $PREFIX/include/libxml2/libxml $PREFIX/include/

cd $msfpath
curl -LO https://github.com/rapid7/metasploit-framework/archive/$msfvar.tar.gz

tar -xf $msfpath/$msfvar.tar.gz
mv $msfpath/metasploit-framework-$msfvar $msfpath/metasploit-framework
cd $msfpath/metasploit-framework

# Update rubygems-update
if [ "$(gem list -i rubygems-update 2>/dev/null)" = "false" ]; then
	gem install --no-document --verbose rubygems-update
fi

# Update rubygems
update_rubygems

# Install bundler
gem install --no-document --verbose bundler:1.17.3

# Installing all gems 
bundle config build.nokogiri --use-system-libraries
bundle install -j3
echo "Gems installed"

# Some fixes
sed -i "s@/etc/resolv.conf@$PREFIX/etc/resolv.conf@g" $msfpath/metasploit-framework/lib/net/dns/resolver.rb
find "$msfpath"/metasploit-framework -type f -executable -print0 | xargs -0 -r termux-fix-shebang
find "$PREFIX"/lib/ruby/gems -type f -iname \*.so -print0 | xargs -0 -r termux-elf-cleaner

echo "Creating database"

mkdir -p $msfpath/metasploit-framework/config && cd $msfpath/metasploit-framework/config
curl -LO https://raw.githubusercontent.com/Hax4us/Metasploit_termux/master/database.yml

mkdir -p $PREFIX/var/lib/postgresql
pg_ctl -D "$PREFIX"/var/lib/postgresql stop > /dev/null 2>&1 || true

if ! pg_ctl -D "$PREFIX"/var/lib/postgresql start --silent; then
    initdb "$PREFIX"/var/lib/postgresql
    pg_ctl -D "$PREFIX"/var/lib/postgresql start --silent
fi
if [ -z "$(psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='msf'")" ]; then
    createuser msf
fi
if [ -z "$(psql -l | grep msf_database)" ]; then
    createdb msf_database
fi

rm $msfpath/$msfvar.tar.gz

cd ${PREFIX}/bin && curl -LO  https://raw.githubusercontent.com/Hax4us/Hax4us.github.io/master/files/msfconsole && chmod +x msfconsole

ln -sf $(which msfconsole) $PREFIX/bin/msfvenom
cd $msfpath 
bundle install
clear
echo
echo " Metasploit Framework successfully installed"
echo "Try to run msfconsole if this showed"
echo "Traceback (most recent call last):
ruby: No such file or directory -- /data/data/com.termux/files/home/metasploit-framework/msfconsole (LoadError)"
echo "########FIX FOR THAT#########"
echo " cd $PREFIX/etc"
echo " nano bash.bashrc"
echo " paste this in 8th line"
echo " alias msfconsole="'"'"cd $instcon;ruby msfconsole"
echo " alias msfconsole="'"'"cd $instcon;ruby msfvenom"
echo "PLEASE SUBSCRIBE TO Mr.P1r4t3 For this MSF installation."
