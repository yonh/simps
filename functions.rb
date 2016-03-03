# -*- coding: utf-8 -*-

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

def add_project(data)
	file = File.dirname(__FILE__)+"/db/projects"
	json = get_projects	
	json.push data
	File.open(file, 'w') do |f|
		f.puts json.to_json
	end
end

