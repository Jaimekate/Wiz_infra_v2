#!/bin/bash
set -euo pipefail

cat >/etc/yum.repos.d/mongodb-org-4.4.repo <<'EOF'
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF

yum update -y
yum install -y mongodb-org-4.4.29 mongodb-org-server-4.4.29 mongodb-org-shell-4.4.29 mongodb-org-mongos-4.4.29 mongodb-org-tools-4.4.29

systemctl enable mongod
systemctl start mongod

mongo 127.0.0.1:27017/admin <<EOF
db.createUser({user: "${mongo_user}", pwd: "${mongo_pass}", roles:[{role:"root", db:"admin"}]})
EOF

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

cat >/etc/mongod.conf <<EOF
storage:
  dbPath: /var/lib/mongo
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
net:
  port: 27017
  bindIp: 127.0.0.1,$PRIVATE_IP
security:
  authorization: enabled
EOF

systemctl restart mongod

cat >/usr/local/bin/mongo_backup.sh <<'EOF'
#!/bin/bash
set -euo pipefail
TS=$(date -u +%Y-%m-%dT%H-%M-%SZ)
OUT_DIR="/tmp/mongodump-$TS"
ARCHIVE="/tmp/mongodump-$TS.tgz"
BUCKET="${bucket_name}"

mkdir -p "$OUT_DIR"

mongodump --host 127.0.0.1 --port 27017 \
  -u "${mongo_user}" -p "${mongo_pass}" --authenticationDatabase "${mongo_auth_db}" \
  --out "$OUT_DIR"

tar -czf "$ARCHIVE" -C /tmp "mongodump-$TS"
aws s3 cp "$ARCHIVE" "s3://$BUCKET/backups/$TS.tgz"
rm -rf "$OUT_DIR" "$ARCHIVE"
EOF

chmod +x /usr/local/bin/mongo_backup.sh
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/mongo_backup.sh >> /var/log/mongo_backup.log 2>&1") | crontab -
