#!/bin/bash

# 检查是否以root权限运行脚本
if [ "$EUID" -ne 0 ]; then
  echo "请以root权限运行此脚本"
  exit 1
fi

# 更新包管理器的源列表
echo "更新包管理器源列表..."
apt update
if [ $? -ne 0 ]; then
  echo "更新包管理器源列表失败"
  exit 1
fi

# 安装curl、vim和openssl
echo "安装curl、vim和openssl..."
apt install -y curl vim openssl
if [ $? -ne 0 ]; then
  echo "安装软件包失败"
  exit 1
fi

# 生成随机密码
ROOT_PASSWORD=$(openssl rand -base64 16)
AIDEN_PASSWORD=$(openssl rand -base64 16)
if [ $? -ne 0 ]; then
  echo "生成随机密码失败"
  exit 1
fi

# 输出生成的密码
echo "生成的密码如下："
echo "root 用户密码: $ROOT_PASSWORD"
echo "aiden 用户密码: $AIDEN_PASSWORD"

# 添加管理员用户 aiden 并设置其为 sudo 组成员
echo "创建用户 aiden..."
useradd -m -G sudo -s /bin/bash aiden
if [ $? -ne 0 ]; then
  echo "创建用户 aiden 失败"
  exit 1
fi

echo "用户 aiden 创建完成."

# 设置用户 aiden 的密码
echo "设置用户 aiden 的密码..."
echo "aiden:$AIDEN_PASSWORD" | chpasswd
if [ $? -ne 0 ]; then
  echo "设置用户 aiden 密码失败"
  exit 1
fi

# 设置 root 用户的密码
echo "设置 root 用户的密码..."
echo "root:$ROOT_PASSWORD" | chpasswd
if [ $? -ne 0 ]; then
  echo "设置 root 密码失败"
  exit 1
fi

# 为用户 aiden 创建 .ssh 目录并设置权限
echo "设置SSH目录和权限..."
mkdir -p /home/aiden/.ssh
if [ $? -ne 0 ]; then
  echo "创建 .ssh 目录失败"
  exit 1
fi

chmod 700 /home/aiden/.ssh
if [ $? -ne 0 ]; then
  echo "设置 .ssh 目录权限失败"
  exit 1
fi

chown aiden:aiden /home/aiden/.ssh
if [ $? -ne 0 ]; then
  echo "更改 .ssh 目录所有者失败"
  exit 1
fi

# 将提供的公钥复制到 authorized_keys 文件中
echo "设置SSH公钥..."
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICM2rLFwQbFpS69dfTl6MYW6bZBCt0ZAlJpRmB5UIb2u generated-by-azure" > /home/aiden/.ssh/authorized_keys
if [ $? -ne 0 ]; then
  echo "设置 authorized_keys 文件失败"
  exit 1
fi

chmod 600 /home/aiden/.ssh/authorized_keys
if [ $? -ne 0 ]; then
  echo "设置 authorized_keys 文件权限失败"
  exit 1
fi

chown aiden:aiden /home/aiden/.ssh/authorized_keys
if [ $? -ne 0 ]; then
  echo "更改 authorized_keys 文件所有者失败"
  exit 1
fi

# 禁止其他用户使用密码登录
echo "配置SSH服务..."
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
if [ $? -ne 0 ]; then
  echo "禁用密码认证失败"
  exit 1
fi

sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
if [ $? -ne 0 ]; then
  echo "禁用密码认证失败"
  exit 1
fi

sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
if [ $? -ne 0 ]; then
  echo "禁用root登录失败"
  exit 1
fi

sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
if [ $? -ne 0 ]; then
  echo "禁用root登录失败"
  exit 1
fi

# 重启SSH服务以应用更改
echo "重启SSH服务..."
systemctl restart sshd
if [ $? -ne 0 ]; then
  echo "重启SSH服务失败"
  exit 1
fi

echo "初始化完成。"
