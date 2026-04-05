# AWS Setup Guide for Finance App

## 1. Create RDS PostgreSQL Database

1. Go to AWS Console → RDS → Databases → Create Database
2. Choose:
   - **Engine**: PostgreSQL (latest version)
   - **DB Instance Class**: db.t3.micro (free tier eligible)
   - **Storage**: 20 GB gp2
   - **DB Instance Identifier**: `finance-db`
   - **Master Username**: `postgres`
   - **Master Password**: Strong password (save this!)
   - **Public Accessibility**: Yes (so EC2 can reach it)
   
3. Under **Connectivity**, create a new VPC Security Group called `finance-db-sg`:
   - Inbound rule: PostgreSQL (5432) from EC2 security group
   
4. Leave other settings as default and click **Create Database**

5. Wait 5-10 min for DB to be available. Once ready, copy the **Endpoint** (looks like `finance-db.XXXXXXXXX.us-east-1.rds.amazonaws.com`)

## 2. Create EC2 Instance

1. Go to AWS Console → EC2 → Instances → Launch Instance
2. Choose:
   - **AMI**: Ubuntu 22.04 LTS (free tier eligible)
   - **Instance Type**: t3.micro or t2.micro
   - **Create new Security Group** called `finance-app-sg`:
     - SSH 22 from your IP only
     - HTTP 80 from anywhere (0.0.0.0/0)
     - HTTPS 443 from anywhere
   
3. Under **Advanced Details**, keep VPC the same as RDS VPC
4. **Key Pair**: Create/select one and download `.pem` file (keep it safe!)
5. Launch instance

6. After launch, associate an **Elastic IP** (so the address stays fixed):
   - Actions → Network → Manage IP Addresses → Allocate Elastic IP
   - Associate with your instance

7. Copy the **EC2 Public IP** (will use later)

## 3. Verify RDS Security Group

1. Go to RDS → Databases → finance-db
2. Click the **VPC Security Group** link
3. Add inbound rule:
   - **Type**: PostgreSQL
   - **Protocol**: TCP
   - **Port**: 5432
   - **Source**: Select the EC2 security group (`finance-app-sg`)

## 4. Test RDS Connection from EC2

SSH into EC2:
```bash
ssh -i <your-key.pem> ubuntu@<EC2_PUBLIC_IP>
```

Install PostgreSQL client:
```bash
sudo apt update
sudo apt install -y postgresql-client
```

Test connection:
```bash
psql -h finance-db.XXXXXXXXX.us-east-1.rds.amazonaws.com -U postgres -d postgres
```
Enter password when prompted. If it works, type `\q` to exit.

## 5. Create Database & Tables

SSH into EC2 and run:
```bash
psql -h finance-db.XXXXXXXXX.us-east-1.rds.amazonaws.com -U postgres -d postgres -c "CREATE DATABASE finance_db;"
```

Alternatively, the Spring app will auto-create tables via Hibernate (set `spring.jpa.hibernate.ddl-auto=update`).

## 6. Deploy Backend on EC2

Follow [ec2-deploy-commands.md](ec2-deploy-commands.md) but replace the RDS endpoint in [finance.env.example](finance.env.example) with your actual RDS endpoint:

```
SERVER_PORT=8080
SPRING_DATASOURCE_URL=jdbc:postgresql://finance-db.XXXXXXXXX.us-east-1.rds.amazonaws.com:5432/finance_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=<your_rds_password>
```

Keep the app on port 8080. Nginx listens on port 80 and reverse-proxies `/api` requests to the app.

## 7. Verify Backend is Running

```bash
curl http://<EC2_PUBLIC_IP>/api/transactions
```

Should return JSON (even if empty).

## 8. Build & Distribute APK

From your local machine in `finance_app/`:
```bash
flutter build apk --release --dart-define=BASE_URL=http://<EC2_PUBLIC_IP>/api
```

Share the APK from `build/app/outputs/flutter-apk/app-release.apk`

## Next Steps (Optional)

- **Add Domain + HTTPS**: Buy a domain, point it to EC2 Elastic IP, use Let's Encrypt on Nginx
- **Auto-scaling**: Use AWS Auto Scaling Groups for multiple EC2 instances behind a load balancer
- **Database Backups**: Enable RDS automated backups in AWS console
- **Monitoring**: Enable CloudWatch monitoring for EC2 and RDS
