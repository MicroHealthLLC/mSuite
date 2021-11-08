
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

        rvm install ruby-2.6.6

        rvm install ruby-devel-2.6.6

        bash -l -c "rvm use 2.6.6 --default"


# be sure git is installed
        yum install git

# Install Redis
        yum install redis
        systemctl start redis
        systemctl enable redis
        
# Install Mysql
        yum install mariadb-server mariadb  OR follow instructions here https://linuxize.com/post/install-mariadb-on-centos-7/#install-mariadb-103-on-centos-7 for client only install for remote databse connections. You will also need to run this "yum install mariadb-shared" after you follow the instructions in the link above 

        yum install mysql-devel
        
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
        passenger_ruby /usr/local/rvm/gems/ruby-2.6.6/wrappers/ruby;
        passenger_instance_registry_dir /var/run/passenger-instreg;

Below "server {" section add these

        passenger_enabled on;
        rails_env production;

# Start Puma
        cd /var/www/mindmap
        bundle exec puma -C config/puma.rb -e production

# restart nginx
you will have to create an nginx service now

        nano /lib/systemd/system/nginx.service
        
---then this below----
        
        Description=The NGINX HTTP and reverse proxy server
        After=syslog.target network-online.target remote-fs.target nss-lookup.target
        Wants=network-online.target
        
        [Service]
        Type=forking
        PIDFile=/run/nginx.pid
        ExecStartPre=/etc/nginx/sbin/nginx -t
        ExecStart=/etc/nginx/sbin/nginx
        ExecReload=/etc/nginx/sbin/nginx -s reload
        ExecStop=/bin/kill -s QUIT $MAINPID
        PrivateTmp=true
        
        [Install]
        WantedBy=multi-user.target

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

        git clone https://github.com/MicroHealthLLC/mindmaps

        nano /var/www/mindmap/config/database.yml

--enter the password for mysql where it says password then save and exit

# go to the cloned directory 
        cd /var/www/mindmap     

        gem install rails

        gem install bundler -v 2.1.4

        yum install nodejs - https://linuxize.com/post/how-to-install-yarn-on-centos-7/
        
        bundle install

        yarn install - https://linuxize.com/post/how-to-install-yarn-on-centos-7/       
        
        rake secret  THEN put that output in config/secrets.yml
        
        rails db:create RAILS_ENV=production
        
        rake db:migrate RAILS_ENV=production
        
        rake db:seed RAILS_ENV=production

        rake assets:precompile RAILS_ENV=production
        
        go into your nginx.conf and configure server_name to your server and configure root to serve /var/www/mindmap/public or where ever you installed the website

        chown -R nginx:nginx *
        
        Service nginx restart
