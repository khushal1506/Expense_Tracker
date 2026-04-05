# EC2 deployment commands (Ubuntu)

## 1) Install dependencies
sudo apt update
sudo apt install -y openjdk-17-jre-headless nginx

## 2) Build jar on your machine (or on EC2)
# From project root
cd finance
./mvnw clean package -DskipTests

## 3) Copy jar + configs to EC2
# Run from local machine
scp -i <KEY.pem> target/finance-0.0.1-SNAPSHOT.jar ubuntu@<EC2_PUBLIC_IP>:/tmp/finance.jar
scp -i <KEY.pem> deploy/finance.service ubuntu@<EC2_PUBLIC_IP>:/tmp/finance.service
scp -i <KEY.pem> deploy/nginx-finance.conf ubuntu@<EC2_PUBLIC_IP>:/tmp/nginx-finance.conf
scp -i <KEY.pem> deploy/finance.env.example ubuntu@<EC2_PUBLIC_IP>:/tmp/finance.env

## 4) Move files on EC2
sudo mkdir -p /opt/finance
sudo mv /tmp/finance.jar /opt/finance/finance.jar
sudo chown -R ubuntu:ubuntu /opt/finance

sudo mkdir -p /etc/finance
sudo mv /tmp/finance.env /etc/finance/finance.env
sudo chmod 600 /etc/finance/finance.env

sudo mv /tmp/finance.service /etc/systemd/system/finance.service
sudo mv /tmp/nginx-finance.conf /etc/nginx/sites-available/finance
sudo ln -sf /etc/nginx/sites-available/finance /etc/nginx/sites-enabled/finance
sudo rm -f /etc/nginx/sites-enabled/default

## 5) Edit environment variables with RDS endpoint
sudo nano /etc/finance/finance.env
# Update SPRING_DATASOURCE_URL with your RDS endpoint (from AWS console)
# Example: jdbc:postgresql://finance-db-instance.XXXXXXXXX.us-east-1.rds.amazonaws.com:5432/finance_db
# Keep SERVER_PORT=8080 (Nginx listens on 80 and proxies to 8080)
# Save (Ctrl+O, Enter, Ctrl+X)

## 6) Start services
sudo systemctl daemon-reload
sudo systemctl enable finance
sudo systemctl start finance
sudo systemctl status finance --no-pager

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

## 7) Build APK with public URL
# From finance_app folder on your dev machine
flutter build apk --release --dart-define=BASE_URL=http://<EC2_PUBLIC_IP>/api

# If you configure a domain + HTTPS, use:
# flutter build apk --release --dart-define=BASE_URL=https://api.yourdomain.com/api

## 8) Quick checks
curl http://<EC2_PUBLIC_IP>/api/transactions
curl http://<EC2_PUBLIC_IP>/
