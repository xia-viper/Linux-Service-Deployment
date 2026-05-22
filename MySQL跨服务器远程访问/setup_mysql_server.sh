#!/bin/bash
# MySQL服务器一键安装配置脚本
# 适用系统：CentOS Stream 9 / Rocky Linux 9
# 使用方法：chmod +x setup_mysql_server.sh && sudo ./setup_mysql_server.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    MySQL远程服务器一键配置脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 变量配置（请根据需要修改）
MYSQL_ROOT_PASSWORD="YourRoot@123456"
MYSQL_REMOTE_USER="remote"
MYSQL_REMOTE_PASSWORD="Remote@123456"
ALLOW_IP="%"  # %表示允许所有IP，可改为具体IP如192.168.56.%

# 1. 安装MySQL
echo -e "${YELLOW}[1/6] 安装MySQL...${NC}"
dnf install mysql-server -y

# 2. 启动并设置开机自启
echo -e "${YELLOW}[2/6] 启动MySQL服务...${NC}"
systemctl start mysqld
systemctl enable mysqld

# 3. 检查临时密码并设置root密码
echo -e "${YELLOW}[3/6] 配置root密码...${NC}"
TEMP_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log 2>/dev/null | tail -1 | awk '{print $NF}')
if [ -n "$TEMP_PASS" ]; then
    mysqladmin -u root -p"$TEMP_PASS" password "$MYSQL_ROOT_PASSWORD" 2>/dev/null
    echo -e "${GREEN}root密码已设置为: $MYSQL_ROOT_PASSWORD${NC}"
else
    # 如果没有临时密码，尝试空密码登录
    mysqladmin -u root password "$MYSQL_ROOT_PASSWORD" 2>/dev/null || true
fi

# 4. 配置远程访问
echo -e "${YELLOW}[4/6] 配置远程访问...${NC}"
cat >> /etc/my.cnf << EOF

# 远程访问配置
bind-address = 0.0.0.0
EOF

# 5. 创建远程用户
echo -e "${YELLOW}[5/6] 创建远程用户...${NC}"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
CREATE USER IF NOT EXISTS '$MYSQL_REMOTE_USER'@'$ALLOW_IP' IDENTIFIED BY '$MYSQL_REMOTE_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_REMOTE_USER'@'$ALLOW_IP';
FLUSH PRIVILEGES;
EOF

# 6. 配置防火墙
echo -e "${YELLOW}[6/6] 配置防火墙...${NC}"
firewall-cmd --permanent --add-port=3306/tcp 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

# 重启MySQL使配置生效
systemctl restart mysqld

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}安装完成！${NC}"
echo -e "${GREEN}MySQL root密码: $MYSQL_ROOT_PASSWORD${NC}"
echo -e "${GREEN}远程用户: $MYSQL_REMOTE_USER / $MYSQL_REMOTE_PASSWORD${NC}"
echo -e "${GREEN}服务器IP: $(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1)${NC}"
echo -e "${GREEN}========================================${NC}"
