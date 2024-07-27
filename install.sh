#!/bin/bash

# 确保脚本在遇到错误时立即退出
set -e

# 检查是否以root权限运行脚本
if [ "$EUID" -ne 0 ]; then
  echo "请以root权限运行此脚本"
  exit 1
fi

# 更新包管理器的源列表
echo "更新包管理器源列表..."
apt update || { echo "更新包管理器源列表失败"; exit 1; }

# 安装curl、vim和openssl
echo "安装curl、vim和openssl..."
apt install -y curl vim openssl || { echo "安装curl、vim和openssl失败"; exit 1; }

# 提示用户输入密码
echo "请输入 root 和 aiden 用户的新密码:"
read -s PASSWORD

# 输出生成的密码
echo "设置的密码如下："
echo "root 用户密码: $PASSWORD"
echo "aiden 用户密码: $PASSWORD"

# 添加管理员用户 aiden 并设置其为 sudo 组成员
echo "创建用户 aiden..."
useradd -m -G sudo -s /bin/bash aiden || { echo "创建用户 aiden 失败"; exit 1; }
echo "用户 aiden 创建完成."

# 设置用户 aiden 的密码
echo "设置用户 aiden 的密码..."
echo "aiden:$PASSWORD" | chpasswd || { echo "设置 aiden 用户密码失败"; exit 1; }

# 设置 root 用户的密码
echo "设置 root 用户的密码..."
echo "root:$PASSWORD" | chpasswd || { echo "设置 root 用户密码失败"; exit 1; }

# 为用户 aiden 创建 .ssh 目录并设置权限
echo "设置SSH目录和权限..."
mkdir -p /home/aiden/.ssh || { echo "创建 .ssh 目录失败"; exit 1; }
chmod 700 /home/aiden/.ssh || { echo "设置 .ssh 目录权限失败"; exit 1; }
chown aiden:aiden /home/aiden/.ssh || { echo "设置 .ssh 目录所有权失败"; exit 1; }

# 将提供的公钥复制到 authorized_keys 文件中
echo "设置SSH公钥..."
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICM2rLFwQbFpS69dfTl6MYW6bZBCt0ZAlJpRmB5UIb2u generated-by-azure" > /home/aiden/.ssh/authorized_keys || { echo "设置 authorized_keys 文件失败"; exit 1; }
chmod 600 /home/aiden/.ssh/authorized_keys || { echo "设置 authorized_keys 文件权限失败"; exit 1; }
chown aiden:aiden /home/aiden/.ssh/authorized_keys || { echo "设置 authorized_keys 文件所有权失败"; exit 1; }

# 禁止其他用户使用密码登录
echo "配置SSH服务..."
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || { echo "配置SSH服务失败"; exit 1; }
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || { echo "配置SSH服务失败"; exit 1; }
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config || { echo "配置SSH服务失败"; exit 1; }
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config || { echo "配置SSH服务失败"; exit 1; }

# 重启SSH服务以应用更改
echo "重启SSH服务..."
systemctl restart sshd || { echo "重启SSH服务失败"; exit 1; }

echo "初始化完成。"
