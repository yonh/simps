#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'awesome_print'
require 'optparse'
require 'json'

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

if arg0 == "count"
	puts get_project_count
end
if arg0 == "new"
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
	system("git clone #{git} /www/#{name}")
	container = "web_#{name}"
	image = "tinystime/php-apache2"
	volume = " -v /www/#{name}/app:/www"
	limit = " -m 200m --memory-swap=200m"
	system("docker run -d --restart=always --name #{container} -p #{port}:80 #{volume} #{limit} #{image}")

	# 保存项目数据
	project = Hash.new
	project['id'] = get_project_count
	project['name'] = name
	project['container'] = container
	project['port'] = port
	project['git'] = git
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

