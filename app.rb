# -*- coding: utf-8 -*-

require 'awesome_print'
require 'docker'
require 'optparse'

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

puts options.inspect


arg0 =  ARGV[0]
Docker.url='unix:///var/run/docker.sock'

require './functions.rb'

if arg0 == "images" then
	system("docker ps")
	#images = Docker::Image.all
	#images.each do |img|
	#	printf("%-15s %-15s %-15s\n", img.id.split(":")[1][0,12], img.info['RepoTags'][0], (img.info['Size']/1000000.0).round(2).to_s+"M")
	#end
end


if arg0 == "new"
	puts "请输入项目名称,唯一，不可重复，仅允许英文:"
	name = STDIN.gets.rstrip
	nginx_config_file = "/etc/nginx/conf.d/"+name+".conf"
	if File.exists?(nginx_config_file) then
                puts "该项目已存在,请选择其他名称"
                exit
        end
	
	puts "请输入项目使用端口:"
	port = STDIN.gets.to_i
	if port < 10000 then
		puts "端口不允许小于10000"
		exit
	end
	
	puts "请输入监听域名:"
	server_name = STDIN.gets.rstrip
	

	nginx_config_tpl = File.read("nginx.conf.tpl")
	nginx_config_tpl = nginx_config_tpl.gsub("{appname}", name)
	nginx_config_tpl = nginx_config_tpl.gsub("{port}", port.to_s)
	nginx_config_tpl = nginx_config_tpl.gsub("{server_name}", server_name)
	
	unless write_to_file(nginx_config_file, nginx_config_tpl) then
		puts "写入配置文件失败"
		exit
	end
	
	
end

