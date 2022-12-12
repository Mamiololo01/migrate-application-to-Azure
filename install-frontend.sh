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