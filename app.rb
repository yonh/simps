#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'awesome_print'
require 'optparse'
require 'json'
require 'docker'

Docker.url='unix:///var/run/docker.sock'

arg0 =  ARGV[0]

require File.dirname(__FILE__) + '/functions.rb'
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

if arg0 == "rm" then
	id = project_select
	del_project(id)
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
	add_project(project)
	
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
		["limit","限制"]]
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
