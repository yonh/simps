#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'awesome_print'
require 'docker'
require 'optparse'
require 'json'

options = {}
option_parser = OptionParser.new do |opts|
  # 这里是这个命令行工具的帮助信息
  opts.banner = 'here is help messages of the command line tool.'

  # Option 作为switch，不带argument，用于将 switch 设置成 true 或 false
  options[:switch] = false
  # 下面第一项是 Short option（没有可以直接在引号间留空），第二项是 Long option，第三项是对 Option 的描述
  opts.on('-s', '--switch', 'Set options as switch') do
    # 这个部分就是使用这个Option后执行的代码
    options[:switch] = true
  end

  # Option 作为 flag，带argument，用于将argument作为数值解析，比如"name"信息
  #下面的“value”就是用户使用时输入的argument
  opts.on('-n NAME', '--name Name', 'Pass-in single name') do |value|
    options[:name] = value
  end

  # Option 作为 flag，带一组用逗号分割的arguments，用于将arguments作为数组解析
  opts.on('-a A,B', '--array A,B', Array, 'List of arguments') do |value|
    options[:array] = value
  end
end.parse!

#puts options.inspect


arg0 =  ARGV[0]
Docker.url='unix:///var/run/docker.sock'

require File.dirname(__FILE__) + '/functions.rb'

if arg0 == "images" then
	system("docker ps")
	#images = Docker::Image.all
	#images.each do |img|
	#	printf("%-15s %-15s %-15s\n", img.id.split(":")[1][0,12], img.info['RepoTags'][0], (img.info['Size']/1000000.0).round(2).to_s+"M")
	#end
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
	image = "tinystime/php-apache2"
	volume = " -v /www/#{name}/app:/var/www/html"
	limit = " -m 200m --memory-swap=200m"
	system("docker run -d --restart=always --name web_#{name} -p #{port}:80 #{volume} #{limit} #{image}")

	# 保存项目数据
	project = Hash.new
	project['id'] = get_project_count
	project['name'] = name
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

