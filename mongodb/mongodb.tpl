#!/usr/bin/env bash
set -eux

sudo apt-get update && sudo apt-get install -y gnupg curl awscli

# Add repo only if not exists
if [ ! -f /etc/apt/sources.list.d/mongodb-org-8.0.list ]; then
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
       sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
       
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/8.0 multiverse" | \
       sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
fi

sudo apt-get update && sudo apt-get install -y mongodb-org

sudo systemctl enable --now mongod

sleep 30

mongosh admin --eval "
db.createUser({
  user: \"admin\",
  pwd: \"admin\",  // Use your actual password here
  roles: [
    { role: \"userAdminAnyDatabase\", db: \"admin\" },
    { role: \"readWriteAnyDatabase\", db: \"admin\" },
    { role: \"dbAdminAnyDatabase\", db: \"admin\" },
    { role: \"clusterAdmin\", db: \"admin\" }
  ]
})
"

sleep 5
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
sudo cat >> /etc/mongod.conf << EOF
security:
  authorization: enabled
EOF

sudo systemctl restart mongod