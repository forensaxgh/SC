#!/bin/bash

# 检查是否以root权限运行脚本
if [ "$EUID" -ne 0 ]; then
  echo "请以root权限运行此脚本"
  exit 1
fi

# 更新包管理器的源列表
echo "更新包管理器源列表..."
apt update

# 安装curl
echo "安装curl..."
apt install -y curl

# 添加管理员用户 aiden 并设置其为 sudo 组成员
echo "创建用户 aiden..."
useradd -m -G sudo -s /bin/bash aiden
echo "用户 aiden 创建完成."

# 设置用户 aiden 的密码
echo "请为用户 aiden 设置密码:"
passwd aiden

# 为用户 aiden 创建 .ssh 目录并设置权限
echo "设置SSH目录和权限..."
mkdir -p /home/aiden/.ssh
chmod 700 /home/aiden/.ssh
chown aiden:aiden /home/aiden/.ssh

# 将提供的公钥复制到 authorized_keys 文件中
echo "设置SSH公钥..."
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICM2rLFwQbFpS69dfTl6MYW6bZBCt0ZAlJpRmB5UIb2u generated-by-azure" > /home/aiden/.ssh/authorized_keys
chmod 600 /home/aiden/.ssh/authorized_keys
chown aiden:aiden /home/aiden/.ssh/authorized_keys

# 禁止其他用户使用密码登录
echo "配置SSH服务..."
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 重启SSH服务以应用更改
echo "重启SSH服务..."
systemctl restart sshd

echo "初始化完成。"
