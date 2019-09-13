# update centos

yum update

yum install -y epel-release yum-utils

yum-config-manager --enable epel

yum clean all && sudo yum update -y

# install ruby

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

curl -sSL https://get.rvm.io | sudo bash -s stable

usermod -a -G rvm `username'

export PATH="$PATH:$HOME/.rvm/bin"

log out then log back in

rvm install ruby-2.5.3

rvm install ruby-devel-2.5.3

bash -l -c "rvm use 2.5.3 --default"

# Install Mysql
yum install mariadb-server mariadb

yum install mysql-devel

systemctl start mariadb

systemctl enable mariadb

mysql_secure_installation

mysql -u root -p

create database mindmaps_dev CHARACTER SET utf8 COLLATE utf8_general_ci;

exit

# be sure git is installed
yum install git

# go to /var/www and from there 
cd /var/www/

git clone https://github.com/MicroHealthLLC/mindmap

nano /var/www/mindmap/config/database.yml

--enter the password for mysql where it says password then save and exit

# go to the cloned directory 
cd /var/www/mindmap

gem install rails

gem install bundler

yum install nodejs

bundle install

rails db:setup 

rake db:seed

rake assets:precompile

# generate your secrets for config/secrets.yml

rake secret

put that output in config/secrets.yml

# Configure Nginx repo for CentOS 7

nano /etc/yum.repos.d/nginx.repo

# then enter this below and save

[nginx-stable]

name=nginx stable repo

baseurl=http://nginx.org/packages/centos/$releasever/$basearch/

gpgcheck=1

enabled=1

gpgkey=https://nginx.org/keys/nginx_signing.key



# Update yum and install nginx
yum update

yum install -y nginx

sudo systemctl enable nginx

# install passenger phusion

yum install -y pygpgme curl

curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo

yum install -y nginx passenger || sudo yum-config-manager --enable cr && sudo yum install -y nginx passenger

# then go edit passenger.conf
nano /etc/nginx/conf.d/passenger.conf

# -where it says passenger_ruby change what you see there to what you see below.  If that doesn't work then do this "which passenger-config" to get the path to put next to passenger_ruby

passenger_ruby /usr/local/rvm/gems/ruby-2.5.3/wrappers/ruby;

--uncomment the line above and the line below along with the passenger_ruby line e.g. remove this"#"

echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# edit nginx.conf
nano /etc/nginx/nginx.conf
add these

        passenger_enabled on;
        rails_env development;


# restart nginx
service nginx restart

# Setup
go to https://your-url/admin

login with temp account admin@example.com with password admin@2018


Change, configure and customize your instance.  callback uri for socialmedia setup below.

https://YourliveSiteDomain/users/auth/linkedin/callback
https://YourliveSiteDomain/users/auth/google_oauth2/callback
https://YourliveSiteDomain/users/auth/facebook/callback
https://YourliveSiteDomain/users/auth/twitter/callback
https://YourliveSiteDomain/users/auth/office365/callback
