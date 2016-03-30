#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#帮助生成获取值的代码
if !ARGV[0] then
	exit
end

# 生成新的action
if ARGV[0] == "new" then
	puts "请输入action name"
	action = STDIN.gets.rstrip
	puts "请输入帮助描述"
	descr = STDIN.gets.rstrip
	system("sed -i '/param_keys = {/a\\\\t\"#{action}\"=>\\t\"#{descr}\",' app.rb")
	f = "if arg0 == \"#{action}\" then\\n\\nend"

	system("sed -i '/# end code$/i#{f}' app.rb")

else
	arr = ARGV[0].split(",")

	arr.each do |item|
		puts "puts \"请输入#{item}\""
		puts "#{item} = STDIN.gets.rstrip"
	end

end




