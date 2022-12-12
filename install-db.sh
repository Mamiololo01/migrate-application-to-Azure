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