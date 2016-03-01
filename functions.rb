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

def get_project_count
	file = File.dirname(__FILE__)+"/db/project_count"
	File.read(file).to_i
end
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

