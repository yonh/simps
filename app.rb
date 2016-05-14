#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'awesome_print'
require 'optparse'
require 'json'
require 'docker'
require File.dirname(__FILE__) + '/functions.rb'

Docker.url='unix:///var/run/docker.sock'

arg0 =  ARGV[0]

param_keys = {
	"new"=>		"新建应用",
	"start"=>	"启动应用",
	"stop"=>	"停止应用",
	"set"=>		"修改应用信息",
	"images"=>	"查看所有镜像",
	"redeploy"=>"更新单个应用镜像",
	"redeployall"=>"重新所有应用的镜像",
	"rm"=>		"删除应用",
	"count"=>	"应用计数",
	"ls"=>		"应用列表",
	"backups"=>	"应用备份列表",
	"info"=>	"应用信息详情",
	"pull"=>	"拉取其他服务器的文件",
	"sls"=>	"查看所有server",
	"sset"=>	"修改server信息",
	"srm"=>		"删除server信息",
	"snew"=>	"新增server"
}

# 输出
if param_keys.include?(arg0) == false then
	layout = "%12s  %-20s\n"
	param_keys.each do |k, v|
		printf(layout, k, v)
	end

	#color_print("也可以使用tiny_dep info id 显示详情", "yellow")
end

if arg0 == "images" then
	system("docker ps")
	#images = Docker::Image.all
	#images.each do |img|
	#	printf("%-15s %-15s %-15s\n", img.id.split(":")[1][0,12], img.info['RepoTags'][0], (img.info['Size']/1000000.0).round(2).to_s+"M")
	#end
end

# 停止项目
if arg0 == "start" then
	projects = get_projects
	projects.each do |proj|
		printf("%-2s %-15s\n", proj['id'], proj['name'])
	end

	puts "请输入要启动的项目id"
	id = STDIN.gets.to_i
	project = get_project_by_id(id)
	if project then
		system("docker start #{project['container']}")
	else
		puts "项目不存在"
	end
end

# 停止项目
if arg0 == "stop" then
	projects = get_projects
	projects.each do |proj|
		printf("%-2s %-15s\n", proj['id'], proj['name'])
	end

	puts "请输入要停止的项目id"
	id = STDIN.gets.to_i
	project = get_project_by_id(id)
	if project then
		system("docker stop #{project['container']}")
	else
		puts "项目不存在"
	end
end

# 重新部署
if arg0 == "redeploy" then
	id = project_select
	redeploy(id)
end
# 重新部署所有
if arg0 == "redeployall" then
	projects =  get_projects
	projects.each do |proj|
		redeploy(proj['id'])
	end
end

# 删除项目
if arg0 == "rm" then
	id = project_select
	del_project(id)
end


if arg0 == "pull" then
	#puts get_servers
	serv = get_server_by_id(server_select)
	if serv then
		cmd = "rsync -avzP #{serv["user"]}@#{serv["ip"]}:/opt/tiny_dep/backups /opt/tiny_dep/"
		system(cmd);
	end
end

if arg0 == "count" then
	puts get_project_count
end
if arg0 == "new" then
	puts "请输入项目名称,唯一，不可重复，仅允许英文数字:"
	name = STDIN.gets.rstrip
	nginx_config_file = "/etc/nginx/conf.d/"+name+".conf"
	if File.exists?(nginx_config_file) or get_project(name)!=nil then
		puts "该项目已存在,请选择其他名称"
      	exit
    end
	
	port = get_project_count + 10000
	
	puts "请输入域名,多个域名使用空格间隔:"
	server_name = STDIN.gets.rstrip

	nginx_config_tpl = File.read(File.dirname(__FILE__)+"/nginx.conf.tpl")
	nginx_config_tpl = nginx_config_tpl.gsub("{appname}", name)
	nginx_config_tpl = nginx_config_tpl.gsub("{port}", port.to_s)
	nginx_config_tpl = nginx_config_tpl.gsub("{server_name}", server_name)
	
	unless write_to_file(nginx_config_file, nginx_config_tpl) then
		puts "写入配置文件失败"
		exit
	end

	puts "请输入项目git库下载地址"
	git  = STDIN.gets.rstrip	
	# 下载代码
	app_dir= "/www/#{name}"
	system("git clone #{git} #{app_dir}")
	system("chown www-data.www-data #{app_dir} -R")


	puts "是否创建数据库(y/n)"
	y_or_n = STDIN.gets.rstrip
	if y_or_n == "y" || y_or_n == "Y" then
		puts "请输入数据库名称(数据库会加上前缀db_)"
		dbname = "db_" + STDIN.gets.rstrip
		puts "请输入数据库用户(数据库会加上前缀u_)"
		dbuser = "u_" + STDIN.gets.rstrip
		puts "请输入数据库用户密码,留空则系统自动生成"
		dbpass = STDIN.gets.rstrip
		dbpass = [*('a'..'z'),*('A'..'Z'),*(0..9)].shuffle[0..19].join if dbpass==""
	else
		dbname=""
		dbuser=""
		dbpass=""
	end

	image = image_select
	if image == nil then
		image = "tinystime/php-apache2:latest"
	end

	container = "web_#{name}"
	volume = "/www/#{name}/app:/www"
	limit = "-m 200m --memory-swap=200m"
	system("docker run -d --restart=always --name #{container} -p #{port}:80 -v #{volume} #{limit} #{image}")

	# 保存项目数据
	project = Hash.new
	project['id'] = get_project_count
	project['name'] = name
	project['app_dir'] = app_dir
	project['container'] = container
	project['port'] = port
	project['git'] = git
	project['volume'] = volume
	project['image'] = image
	project['limit'] = limit
	project['update_hook_url'] = project_update_url(name)
	project['db_name'] = dbname
	project['db_user'] = dbuser
	project['db_pass'] = dbpass
	add_project(project)

	# 创建数据库
	if dbname && dbuser && dbpass then
		puts 'create db'
		create_user('%', dbuser , dbpass)
		puts 'create db user'
		create_db(dbname, dbuser)
	end
	
	#项目数自增
	inc_project_count	
	url = project_update_url(name)
	puts "请配置您的项目的webhook地址为: #{url}"
	system("service nginx reload > /dev/null")
end

# 查看项目列表
if arg0 == "ls" then
	layout = "%-3s %-20s\n"
	printf(layout, "id", "项目名称")
	projects = get_projects
	projects.each do |proj|
		printf(layout, proj['id'], proj['name'])
	end

	color_print("也可以使用tiny_dep info id 显示详情", "yellow")
end

# 查看项目列表
if arg0 == "sls" then
	layout = "%-3s %-20s %-10s\n"
	printf(layout, "id", "ip", "user")
	projects = get_servers
	projects.each do |proj|
		printf(layout, proj['id'], proj['ip'], proj['user'])
	end
end

# 新增server
if arg0 == "snew" then
	puts "请输入server ip"
	ip = STDIN.gets.rstrip
	puts "请输入server user"
	user = STDIN.gets.rstrip

	data = Hash.new
	data['id'] = get_sequence
	data['ip'] = ip
	data['user'] = user
	add_server(data)
end

# 修改server信息
if arg0 == "sset" then
	key_array = [
		["ip", "ip"],
		["user", "用户名"]
	]

	id = server_select
	serv = get_server_by_id(id)
	if serv == nil then
		puts 'server不存在'
		exit
	end

	new_val = Hash.new
	key_array.each do |val|
		printf("请输入[%s]的替换值,空为不更改,原(%s)\n", val[1], serv[val[0]])
		value = STDIN.gets.rstrip
		if value == "" then
			new_val[val[0]] = serv[val[0]]
		else
			new_val[val[0].to_s] = value
		end
	end
	new_val['id'] = serv['id']
	update_server_info(new_val)
	puts "ok"
end

# 删除server
if arg0 == "srm" then
	id = server_select
	del_server(id)
end

if arg0 == "backups" then
	layout = "%-3s %-20s\n"
	printf(layout, "id", "项目名称")
	projects = get_projects
	projects.each do |proj|
		printf(layout, proj['id'], proj['name'])
	end

	color_print("也可以使用tiny_dep info id 显示详情", "yellow")
end

# 查看项目详情
if arg0 == "info" then
	key_array = [
		["id","项目id"],
		["name", "名称"],
		["port", "端口"],
		["git", "git地址"],
		["image", "镜像"],
		["container", "容器"],
		["update_hook_url", "hook更新地址"],
		["limit","限制"],
		["db_name","数据库"],
		["db_user","数据库用户"],
		["db_pass","数据库密码"]]
	id = ARGV[1]
	layout = "%-15s : %-10s\n"
	proj = get_project_by_id(id.to_i)
	if proj then
		key_array.each do |arr|
			printf(layout, arr[1], proj[arr[0]])
		end
	else
		puts "项目不存在"
	end
		
		
end

if arg0 == "set" then
	# 目前大部分内容都不可修改
	key_array = [
		#["name", "名称"],
		#["port", "端口"],
		#["git", "git地址"],
		#["image", "镜像"],
		#["container", "容器"],
		#["update_hook_url", "hook更新地址"],
		["limit","限制"]]

	proj = get_project_by_id(project_select)
	if proj == nil then
		 puts "项目不存在"
		 exit
	end
	new_val = Hash.new
	key_array.each do |val|
		printf("请输入[%s]的替换值,空为不更改,原(%s)\n", val[1], proj[val[0]])
		value = STDIN.gets.rstrip
		if value == "" then
			new_val[val[0]] = proj[val[0]]
		else
			new_val[val[0].to_s] = value
		end
	end
	new_val['id'] = proj['id']
	update_project_info(new_val)
	puts "ok"
end


# end code
