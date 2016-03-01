#!/bin/bash
app_dir="/opt/tiny_dep"
if [ ! -d $app_dir ]; then  
	mkdir -p $app_dir
	echo "export PATH=\"\$PATH:$app_dir\"" >> ~/.bashrc
	echo "请运行source ~/.bashrc使环境变量生效"
fi

if [ ! -f "/usr/bin/ruby" ]; then
	apt-get update && apt-get install -y ruby && gem install bundle
fi

bundle install


cp app.rb $app_dir/tiny_dep
chmod +x $app_dir/tiny_dep



