# Full installation process for Webistor Server.
APIBRANCH=master
UIBRANCH=master

# Install Node.
apt-get install curl
curl -sL https://deb.nodesource.com/setup | bash -
apt-get install nodejs

# Install MongoDB.
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
apt-get update
apt-get install mongodb-org

# Install mail server.
apt-get install postfix

# Create Node user.
UNAME=node
UHOME=/home/$UNAME
useradd -m -d $UHOME $UNAME
chown -R $UNAME:$UNAME $UHOME

# Install global node modules.
npm install -g forever coffee-script brunch bower

# Remove old install.
rm -rf $UHOME/webistor

# Install Webistor API.
sudo -u $UNAME -- bash -c "
  mkdir ~/webistor
  cd ~/webistor
  git clone -b $APIBRANCH https://github.com/Tuxion/webistor-api.git api
  cd api
  npm install
  nano src/config.coffee
  cake build
" || exit $?

# Move to init.d
cd $UHOME/webistor/api
cp init.d /etc/init.d/webistor
chmod +x /etc/init.d/webistor

# Install Webistor UI.
sudo -u $UNAME -- bash -c "
  cd $UHOME/webistor
  git clone -b $UIBRANCH https://github.com/webistor/webistor-app.git ui
  cd ui
  npm install
  bower install
  nano app/config.coffee
  brunch build --production
" || exit $?
