#!/bin/bash
app_dir="/opt/tiny_dep"
backups_dir="/opt/tiny_dep/backups"
if [ ! -d $app_dir ]; then  
	mkdir -p $app_dir
	cp -r db $app_dir/
	echo "export PATH=\"\$PATH:$app_dir\"" >> ~/.bashrc
	echo "请运行source ~/.bashrc使环境变量生效"
fi
if [ ! -d $backups_dir ]; then  
	mkdir -p $backups_dir
fi
if [ ! -f "/usr/bin/ruby" ]; then
	apt-get update && apt-get install -y ruby-dev nginx make && gem install bundle
fi

# install docker
bash docker-install.sh

bundle install

echo ""
cp app.rb $app_dir/tiny_dep && chmod +x $app_dir/tiny_dep
cp project_update_listen.rb $app_dir/project_update_listen && chmod +x $app_dir/project_update_listen
cp functions.rb $app_dir/
cp nginx.conf.tpl $app_dir/

# 设置www-data的ssh-key
mkdir -p /var/www && chown www-data.www-data /var/www -R
sudo -u www-data ssh-keygen -t rsa
ssh-keyscan -p 2222 -t ecdsa,rsa 45.55.4.132 >> /var/www/.ssh/known_hosts
chown www-data.www-data /var/www -R

# 设置更新程序开机启动
if [ ! -f "/etc/init.d/tiny_update_hook" ]; then
	cp tiny_update_hook.sh /etc/init.d/tiny_update_hook
	update-rc.d tiny_update_hook defaults
else
	cp tiny_update_hook.sh /etc/init.d/tiny_update_hook
fi

echo "请修改文件$app_dir/db/server_ip内容更改为您服务器ip"
