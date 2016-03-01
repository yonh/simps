#!/bin/bash
app_dir="/opt/tiny_dep"
if [ ! -d $app_dir ]; then  
	mkdir -p $app_dir
	echo "export PATH=\"\$PATH:$app_dir\"" >> ~/.bashrc
	echo "请运行source ~/.bashrc使环境变量生效"
fi

cp app.rb $app_idr/tiny_dep
chmod +x $app_idr/tiny_dep

