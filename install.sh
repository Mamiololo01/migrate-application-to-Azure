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
create database treefarm;
use treefarm;

drop table if exists items;
create table items (
  id int not null auto_increment,
  name varchar(255) not null,
  description varchar(255) not null,
  price int not null,
  primary key (id)
);

insert into items (name, description, price) values ("Douglas Fir", "Pseudotsuga menziesii", 5);
insert into items (name, description, price) values ("Atlantic White Cedar", "Chamaecyparis thyoides", 25);
insert into items (name, description, price) values ("Lawson's Cypress", "Chamaecyparis lawsoniana", 7);
insert into items (name, description, price) values ("Northern White Cedar", "Thuja occidentalis", 10);
insert into items (name, description, price) values ("Norway Spruce", "Picea abies", 35);
insert into items (name, description, price) values ("Fraser Fir", "Abies fraseri", 5);

create user 'treefarm' identified with mysql_native_password by '6qNaYDdq3pBc34';
grant select on treefarm.items to treefarm;
EOF

# API
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt update
apt install -y gcc g++ make
apt install -y npm nodejs
apt-mark hold nodejs

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | sudo -E bash -
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 18


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
User=treefarm
Group=treefarm
Environment=DB_HOST=127.0.0.1
Environment=DB_USER=treefarm
Environment=DB_PASS=6qNaYDdq3pBc34

[Install]
WantedBy=multi-user.target
EOF

useradd treefarm
chown -R treefarm:treefarm /opt/content-move-application-cloud-azure

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
User=treefarm
Group=treefarm
Environment=PORT=8081

[Install]
WantedBy=multi-user.target
EOF

cd /opt/content-move-application-cloud-azure/frontend
rm package-lock.json
npm install
npm run build
chown -R treefarm:treefarm /opt/content-move-application-cloud-azure
systemctl daemon-reload
systemctl enable content-move-application-cloud-azure
systemctl restart content-move-application-cloud-azure
