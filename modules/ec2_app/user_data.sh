#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ─── Step 1: Start Python immediately so ALB health checks pass right away ────
# nginx takes a few minutes to install — Python bridges that gap.

mkdir -p /var/www/html

cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Insight Edge</title>
</head>
<body>
  <div style="height:100vh;display:flex;justify-content:center;align-items:center;background-color:#fff;font-family:Arial,sans-serif;">
    <div style="text-align:center;">
      <img
        src="https://insight-edgecs.com/wp-content/uploads/2025/10/iecs_transparent.png"
        alt="Logo"
        style="max-width:220px;height:auto;margin-bottom:15px;"
      />
      <h2 style="margin:0;">Welcome to ${env_display} Environment</h2>
    </div>
  </div>
</body>
</html>
HTML

echo "OK" > /var/www/html/health

nohup python3 -m http.server 8080 --directory /var/www/html >> /var/log/user-data.log 2>&1 &
PYTHON_PID=$!
echo "Python server started (pid $PYTHON_PID)" >> /var/log/user-data.log

# ─── Step 2: Install nginx (Python keeps the ALB happy during this) ───────────

apt-get update -y  >> /var/log/user-data.log 2>&1 || true
apt-get install -y nginx >> /var/log/user-data.log 2>&1 || true

# ─── Step 3: Configure nginx for React SPA on port 8080 ──────────────────────
# try_files $uri $uri/ /index.html — returns index.html for all unknown routes
# so React's client-side router (React Router etc.) works correctly.

rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/app << 'NGINXCONF'
server {
    listen 8080;
    root /var/www/html;
    index index.html;

    location /health {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINXCONF

ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app

if nginx -t >> /var/log/user-data.log 2>&1; then
  # Kill Python first to free port 8080, then restart nginx with the new config.
  # apt-get auto-starts nginx on port 80; 'start' is a no-op if already running,
  # so 'restart' is required to load our port-8080 config.
  kill $PYTHON_PID 2>/dev/null || true
  systemctl enable nginx
  systemctl restart nginx
  echo "nginx restarted on :8080 — Python server stopped" >> /var/log/user-data.log
else
  echo "nginx config test failed — Python server remains active" >> /var/log/user-data.log
fi

# ─── Step 4: CloudWatch Agent (best-effort, runs after nginx is up) ───────────

CW_DEB="amazon-cloudwatch-agent.deb"
wget -q "https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/$CW_DEB" \
  -O "/tmp/$CW_DEB" >> /var/log/user-data.log 2>&1 \
  && dpkg -i "/tmp/$CW_DEB" >> /var/log/user-data.log 2>&1 \
  && rm -f "/tmp/$CW_DEB" || true

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "agent": { "metrics_collection_interval": 60, "run_as_user": "cwagent" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/ec2/${project_name}/${environment}/nginx-access",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/ec2/${project_name}/${environment}/nginx-error",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
      "InstanceId": "$${aws:InstanceId}"
    },
    "aggregation_dimensions": [["AutoScalingGroupName"]],
    "metrics_collected": {
      "mem":  { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["disk_used_percent"], "resources": ["/"] },
      "cpu":  { "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"], "totalcpu": true }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json >> /var/log/user-data.log 2>&1 || true

# ─── App directories ──────────────────────────────────────────────────────────

mkdir -p /opt/app /var/log/app
useradd -r -s /bin/false appuser 2>/dev/null || true
chown appuser:appuser /opt/app /var/log/app

echo "Bootstrap complete: ${project_name} ${environment}" >> /var/log/user-data.log
