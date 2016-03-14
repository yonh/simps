# -*- coding: utf-8 -*-
require 'json'
require 'docker'

Docker.url='unix:///var/run/docker.sock'

def write_to_file (file, txt)
	if File.exists?(file) then
		puts "文件:#{file}已存在,写入失败"
		false
	else
		File.open(file, "w") do |f|
			f.puts txt
		end
		true
	end	
end

# 获取项目数量
def get_project_count
	file = File.dirname(__FILE__)+"/db/project_count"
	File.read(file).to_i
end

# 项目数量增加1
def inc_project_count
	file = File.dirname(__FILE__)+"/db/project_count"
	count = File.read(file).to_i
	count += 1
	File.open(file, "w") { |f| f.puts count }
end

# 打印项目更新地址
def project_update_url(name)
	file = File.dirname(__FILE__)+"/db/server_ip"
	ip = File.read(file).rstrip
	"http://#{ip}:9999/update/#{name}"
end

def get_projects
	file = File.dirname(__FILE__)+"/db/projects"
	unless File.file?(file) then system("echo '[]'> #{file}") end

	return JSON.parse(File.read(file))
end

def get_project(name)
	projects = get_projects
	projects.each do |p|
		if p['name'] == name then return p end
	end
	nil
end

def get_project_by_id(id)
	if id!=nil then
		projects = get_projects
		projects.each do |p|
			if p['id'] == id then return p end
		end
	end
end

def add_project(data)
	file = File.dirname(__FILE__)+"/db/projects"
	json = get_projects	
	json.push data
	File.open(file, 'w') do |f|
		f.puts json.to_json
	end
end

def del_project(id)
	proj = get_project_by_id(id)
	if proj != nil then
                # 删除nginx配置文件
                system("rm -rf /etc/nginx/conf.d/#{proj['name']}.conf")
                # 删除容器
                system("docker rm -f #{proj['container']}")
                # 删除本地文件
                system("rm -rf #{proj['app_dir']}")
                # 删除项目记录
		projects = get_projects
		projects.delete_if { |pp| pp['id'] == id }
		file = db_file("projects")
        	File.open(file, 'w') do |f|
               		f.puts projects.to_json
        	end
                # 删除数据库
        end
end

def db_file(file)
	File.dirname(__FILE__)+"/db/" + file
end
def get_auth_ip
	file = db_file("auth_ip")
        unless File.file?(file) then system("echo '[]'> #{file}") end
        return JSON.parse(File.read(file))
end
def add_auth_ip(ip)
	file = db_file("auth_ip")
	json = get_auth_ip
	if json.index(ip)==nil then
		json.push ip
		File.open(file,"w") do |f|
			f.puts json.to_json
		end
	end
end

# 选择项目并返回项目信息,不存在返回nil
def project_select
	projects = get_projects
        projects.each do |proj|
                printf("%-2s %-15s\n", proj['id'], proj['name'])
        end

        puts "请选择项目 (0取消)"
        id = STDIN.gets.to_i
	if id==0 then
		nil
	else
		id
	end
end

# 选择镜像,不存在返回nil
def image_select 
	hash = Hash.new
	images = Docker::Image.all
	index = 0
	images.each do |img|
		image = img.info['RepoTags'][0].to_s
		if image != "<none>:<none>" then
			index += 1
			hash[index] = image
			printf("%-2s %-15s\n", index, image);
		end
	end
	puts "请选择镜像 (0取消)"
	id = STDIN.gets.to_i
	if id==0 then
		nil
	else
		hash[id]
	end
end

