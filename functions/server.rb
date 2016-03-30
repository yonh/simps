#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'json'

# 获取所有服务器列表
def get_servers
	json = parse_json_file("config")
	json["servers"]
end

# 根据id获取server信息
def get_server_by_id(id)
	if id!=nil then
		servers = get_servers
		servers.each do |serv|
			if serv['id'] == id then return serv end
		end
	end
end

# 选择其他服务器
def server_select
	servers = get_servers
    servers.each do |serv|
    	printf("%-2s %-15s\n", serv['id'], serv['ip'])
    end

    puts "请选择server (0取消)"
    id = STDIN.gets.to_i
	if id==0 then
		nil
	else
		id
	end
end

# 添加server
def add_server(data)
	json = get_servers
	json.push data
	write_json('servers', json)
end

# 删除server
def del_server(id)
	servers = get_servers
	servers.delete_if { |s| s['id'] == id }
	write_json("servers", servers);
end
