#!/bin/bash
# MySQL远程连接测试脚本
# 使用方法：chmod +x test_mysql_connection.sh && ./test_mysql_connection.sh

# 配置
SERVER_IP="192.168.56.110"  # 改成你的服务器IP
SERVER_PORT="3306"
MYSQL_USER="remote"
MYSQL_PASSWORD="Remote@123456"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    MySQL远程连接测试${NC}"
echo -e "${GREEN}========================================${NC}"

# 1. 检查MySQL客户端是否安装
echo -e "${YELLOW}[1/4] 检查MySQL客户端...${NC}"
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}MySQL客户端未安装，正在安装...${NC}"
    sudo apt update && sudo apt install mysql-client -y
fi

# 2. 测试网络连通性
echo -e "${YELLOW}[2/4] 测试网络连通性...${NC}"
if ping -c 2 $SERVER_IP &> /dev/null; then
    echo -e "${GREEN}✓ 服务器 $SERVER_IP 可达${NC}"
else
    echo -e "${RED}✗ 服务器 $SERVER_IP 不可达，请检查网络${NC}"
    exit 1
fi

# 3. 测试端口连通性
echo -e "${YELLOW}[3/4] 测试端口连通性...${NC}"
if command -v nc &> /dev/null; then
    nc -zv $SERVER_IP $SERVER_PORT 2>&1 | grep -q "succeeded" && \
        echo -e "${GREEN}✓ 端口 $SERVER_PORT 可达${NC}" || \
        echo -e "${RED}✗ 端口 $SERVER_PORT 不可达${NC}"
else
    echo -e "${YELLOW}nc未安装，跳过端口测试${NC}"
fi

# 4. 测试MySQL登录
echo -e "${YELLOW}[4/4] 测试MySQL登录...${NC}"
if mysql -h $SERVER_IP -u $MYSQL_USER -p"$MYSQL_PASSWORD" -e "SELECT 1" &> /dev/null; then
    echo -e "${GREEN}✓ MySQL连接成功！${NC}"
    
    # 显示数据库列表
    echo -e "${YELLOW}数据库列表:${NC}"
    mysql -h $SERVER_IP -u $MYSQL_USER -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;"
else
    echo -e "${RED}✗ MySQL连接失败，请检查用户名/密码${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}测试完成！${NC}"
