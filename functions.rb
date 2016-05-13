#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'json'
require 'docker'

Docker.url='unix:///var/run/docker.sock'


Dir.glob( File.dirname(__FILE__) + "/functions/*.rb" ).each { |file|
	require file
}

# 写入到config文件
# field key
# value 覆盖值
def write_json(key, value)
	file = File.dirname(__FILE__)+"/db/config"
	json = parse_json_file("config")
	json[key] = value

	File.open(file, 'w') do |f|
		f.puts json.to_json
	end

end
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
	file = db_file("project_count")
	File.read(file).to_i
end

# 获取序列id
def get_sequence
	file = db_file("sequence")
	# 默认为0
	unless File.file?(file) then system("echo '0'> #{file}") end
	seq = File.read(file).to_i + 1
	File.open(file, "w") { |f| f.puts seq }
	seq
end

# 解析json文件,如果不存在则自动创建
def parse_json_file(name)
	file = db_file(name)
	unless File.file?(file) then system("echo '[]'> #{file}") end

	return JSON.parse(File.read(file))
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
# 获取所有项目
def get_projects
	parse_json_file("projects")
end

# 根据name获取项目
def get_project(name)
	projects = get_projects
	projects.each do |p|
		if p['name'] == name then return p end
	end
	nil
end

# 根据id获取项目信息
def get_project_by_id(id)
	if id!=nil then
		projects = get_projects
		projects.each do |p|
			if p['id'] == id then return p end
		end
	end
end

# 添加项目
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
		projects.delete_if { |proj| proj['id'] == id }
		file = db_file("projects")
        File.open(file, 'w') do |f|
            f.puts projects.to_json
        end
            # 删除数据库
	end
end

# 更新project信息
def update_project_info(data)
	change_keys = {}
	change = false
	projects = get_projects
	project_name = ""
	projects.each do |proj|
		if proj['id'] == data['id'] then
			project_name = proj["name"]
			change = true
			data.each do |k, v|
				if proj[k] != v then
					change_keys[k] = 1
				end
				proj[k] = v
			end
			break
		end
	end
	# save change
	if change then
		
		# 修改项目git地址
		if change_keys.has_key?("git") then
			command = "cd /www/#{project_name};"
			command+= "git remote rm origin;"
			command+= "git remote add origin " + data["git"]
			system(command)
		end


		file = db_file("projects")
        File.open(file, 'w') do |f|
       		f.puts projects.to_json
        end
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

def redeploy(id)
	project = get_project_by_id(id)
	if project then
		system("docker rm -f #{project['container']}")
		command = "docker run -d --restart=always --name #{project['container']}"
		command+= " -p #{project['port']}:80"
		command+= " -v #{project['volume']}"
		command+= " #{project['limit']}"
		command+= " #{project['image']}"
		system(command)
	end
end

def color_print(text, color)
	if color == "white" then
		puts "\033[1m#{text}\033[0m"
	elsif color == "yellow"
		puts "\033[33m#{text}\033[0m"
	elsif color == "green"
		puts "\033[32m#{text}\033[0m"
	end
end


# 备份仙姑
def backup(id)
	proj = get_project_by_id(id)
	time = Time.new
	filename =  proj["name"] + "_" + time.strftime("%y%m%d-%H%M%S") + ".tar.gz"
	success = system("tar -C /www -czf backups/#{filename} #{proj['name']} 2>/dev/null")
	if success then
		# 添加备份记录
		id = get_sequence
		data = Hash.new
		data["id"] = get_sequence
		data["pid"] = proj['id']
		data["filename"] = filename
		data["time"] = time.strftime("%Y-%m-%d %H:%M:%S")
		#data["size"] = File.size("backups/"+filename)
		data["size"] = `du -h backups/#{filename}|awk '{print $1}'`.rstrip
		add_backup_redord(data)
	else
		# 失败后删除备份文件
		system("rm -f backups/#{filename}")
	end
end

def get_backup_records
	parse_json_file("backups")
end

def get_backup_record_by_id(id)
	if id!=nil then
		backups = get_backup_records 
		backups.each do |b|
			if b['id'] == id then
				return b
			end
		end
	end
end

# 添加备份记录
def add_backup_redord(data)
	json = parse_json_file("backups")
	file = db_file("backups")
	if data then
		json.push data
		File.open(file, 'w') do |f|
			f.puts json.to_json
		end
	end
end

# 删除备份
def del_backup(id)
	b = get_backup_record_by_id(id)
	if b then
		success = system("rm backups/#{b['filename']}")
		if success then
			bs = get_backup_records
			bs.delete_if { |back| back['id'] == id }
			file = db_file("backups")
			File.open(file, 'w') do |f|
				f.puts bs.to_json
			end
		end
	end
end
