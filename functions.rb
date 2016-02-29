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
