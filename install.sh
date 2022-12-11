#! /bin/bash

# Database
until apt-get remove -y unattended-upgrades; do sleep 5; done

export DEBIAN_FRONTEND=noninteractive

echo "mysql-apt-config mysql-apt-config/repo-codename select bionic" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/repo-distro select ubuntu" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/repo-url string http://repo.mysql.com/apt/" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-preview select Disabled" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-product select Ok" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-server select mysql-5.7" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-tools select Enabled" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/unsupported-platform select ubuntu bionic" | debconf-set-selections
echo "mysql-apt-config/enable-repo select mysql-5.7-dmr" | debconf-set-selections

wget https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb
dpkg --install mysql-apt-config_0.8.22-1_all.deb

apt update
apt install -y --allow-downgrades -f mysql-client=5.7* mysql-community-server=5.7* mysql-server=5.7*
apt-mark hold mysql-client mysql-community-server mysql-server
until echo "show databases;" | mysql; do sleep 5; done
cat << EOF | mysql
create database plantshop;
use plantshop;

drop table if exists items;
create table items (
  id int not null auto_increment,
  name varchar(255) not null,
  description varchar(255) not null,
  price int not null,
  primary key (id)
);

insert into items (name, description, price) values ("Strawberry", "A strawberry plant.", 5);
insert into items (name, description, price) values ("Raphidophora", "Also called monstera minima.", 25);
insert into items (name, description, price) values ("Aloe Vera", "Produces a medicinal gel.", 9);
insert into items (name, description, price) values ("Watermelon seeds", "A packet of watermelon seeds.", 1);
insert into items (name, description, price) values ("Iresine", "Also called bloodleaf due to its red leaves.", 9);
insert into items (name, description, price) values ("String of Pearls", "A small succulent plant.", 5);

create user 'plantshop' identified with mysql_native_password by '6qNaYDdq3pBc34';
grant select on plantshop.items to plantshop;
EOF

# API
# curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt update
apt install -y nodejs
apt-mark hold nodejs

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | sudo -E bash -
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm install 18.3.0


cd /opt
rm -rf content-move-application-cloud-azure
git clone https://github.com/ACloudGuru-Resources/content-move-application-cloud-azure.git

cd /opt/content-move-application-cloud-azure/api
npm install
cat << EOF > /etc/systemd/system/content-move-application-cloud-azure.service
[Service]
WorkingDirectory=/opt/content-move-application-cloud-azure/api
ExecStart=node server.js
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=ctaws-plant-shop-api
User=plantshop
Group=plantshop
Environment=DB_HOST=127.0.0.1
Environment=DB_USER=plantshop
Environment=DB_PASS=6qNaYDdq3pBc34

[Install]
WantedBy=multi-user.target
EOF

useradd plantshop
chown -R plantshop:plantshop /opt/content-move-application-cloud-azure

systemctl daemon-reload
systemctl enable content-move-application-cloud-azure
systemctl restart content-move-application-cloud-azure

# Frontend
npm install -g serve

cat << EOF > /etc/systemd/system/content-move-application-cloud-azure.service
[Service]
WorkingDirectory=/opt/content-move-application-cloud-azure/frontend
ExecStart=serve -s build
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=content-move-application-cloud-azure
User=plantshop
Group=plantshop
Environment=PORT=8081

[Install]
WantedBy=multi-user.target
EOF

cd /opt/content-move-application-cloud-azure/frontend
rm package-lock.json
npm install
npm run build
chown -R plantshop:plantshop /opt/content-move-application-cloud-azure
systemctl daemon-reload
systemctl enable content-move-application-cloud-azure
systemctl restart content-move-application-cloud-azure
