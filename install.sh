#!/bin/bash
app_dir="/opt/tiny_dep"
if [ ! -d $app_dir ]; then  
	mkdir -p $app_dir
	cp -r db $app_dir/
	echo "export PATH=\"\$PATH:$app_dir\"" >> ~/.bashrc
	echo "请运行source ~/.bashrc使环境变量生效"
fi

if [ ! -f "/usr/bin/ruby" ]; then
	apt-get update && apt-get install -y ruby-dev make && gem install bundle
fi

bundle install


echo ""
cp app.rb $app_dir/tiny_dep && chmod +x $app_dir/tiny_dep
cp project_update_listen.rb $app_dir/project_update_listen && chmod +x $app_dir/project_update_listen
cp functions.rb $app_dir/
cp nginx.conf.tpl $app_dir/

echo "请修改文件$app_dir/db/server_ip内容更改为您服务器ip"
