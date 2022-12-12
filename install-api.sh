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