
# update centos

      

        yum-config-manager --enable epel
        
        yum install epel-release
        
        yum install deltarpm
        
        yum clean all &&  yum update -y
        
        Reboot as there are likely kernel updates


# install ruby

        curl -sSL https://rvm.io/pkuczynski.asc | sudo gpg2 --import -
        
        curl -sSL https://get.rvm.io | sudo bash -s stable
        
        usermod -a -G rvm `whoami`

        export PATH="$PATH:$HOME/.rvm/bin"

        log out then log back in

        rvm install ruby-2.6.1

        rvm install ruby-devel-2.6.1

        bash -l -c "rvm use 2.6.1 --default"


# be sure git is installed
        yum install git

# Install Redis
        https://syslint.com/blog/tutorial/how-to-install-latest-redis-on-centos-7/
        systemctl start redis
        systemctl enable redis
        
# Install Mysql
        yum install mariadb-server mariadb  OR follow instructions here https://linuxize.com/post/install-mariadb-on-centos-7/#install-mariadb-103-on-centos-7 for client only install for remote databse connections. You will also need to run this "yum install mariadb-shared" after you follow the instructions in the link above 

        yum install mariadb-devel
        
        systemctl start mariadb

        systemctl enable mariadb

        mysql_secure_installation

# install passenger phusion

        yum install -y pygpgme curl

        curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo

        yum install -y  passenger || sudo yum-config-manager --enable cr && sudo yum install -y  passenger
        
        yum install passenger-devel-6.0.9
        
        yum install libcurl-devel
        
        gem install rack

# install nginx
        
        groupadd nginx
        
        useradd -g nginx nginx
       
        passenger-install-nginx-module
        
choose one.  install it into the directory of your choice.  but for the conf below, chose /etc/nginx/

# edit nginx.conf

        nano /etc/nginx/conf/nginx.conf

Below "http {" section, add these if not already present

        passenger_root /usr/share/ruby/vendor_ruby/phusion_passenger/locations.ini;
        passenger_ruby /usr/local/rvm/gems/ruby-2.6.1/wrappers/ruby;
        passenger_instance_registry_dir /var/run/passenger-instreg;

Below "server {" section add these

        passenger_enabled on;
        rails_env production;

# Start Puma
        cd /var/www/mSuite
        bundle exec puma -C config/puma.rb -e production


----end---

        enable the service
        
        systemctl daemon-reload 

        systemctl enable nginx

        then start the service 
        
        make sure PassengerAgent is executable
        
        chmod +x /usr/lib64/passenger/support-binaries/*
        
        Be sure the logs are sent to /var/logs/nginx in nginx.conf or your conf file
        
        Be sure you have the log directory there
        
        mkdir /var/log/nginx
        
        chown -R nginx:nginx /var/log/nginx

        service nginx start
        
        If you still have permission problems be sure to check selinux
        

# create /var/www and from there 
        mkdir /var/www
        
        cd /var/www/

        git clone https://github.com/MicroHealthLLC/mSuite

        nano /var/www/mSuite/config/database.yml

--enter the password for mysql where it says password then save and exit

# go to the cloned directory 
        cd /var/www/mSuite     

        gem install rails

        gem install bundler -v 2.1.4

        install nodejs
        -  curl --silent --location https://rpm.nodesource.com/setup_14.x | sudo bash -
        -  sudo yum install nodejs
        
        install yarn
        -  curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
        -  sudo rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
        -  sudo yum install yarn

        bundle install

        rake secret  THEN put that output in config/secrets.yml
        
        rails db:create RAILS_ENV=production
        
        rake db:migrate RAILS_ENV=production
        
        rake db:seed RAILS_ENV=production

        rake assets:precompile RAILS_ENV=production
        
        go into your nginx.conf and configure server_name to your server and configure root to serve /var/www/mSuite/public or where ever you installed the website

        chown -R nginx:nginx *
        
        Service nginx restart
  
  # change the default password 
  
go to https://your-url/admin

login with temp account admin@example.com with password password

Change, configure and customize your instance. callback uri for socialmedia setup below to administer the site preferences

https://YourliveSiteDomain/users/auth/google_oauth2/callback

https://YourliveSiteDomain/users/auth/office365/callback

After you have it configured in google or office 365 and you have the proper values entered in the system, restart nginx
