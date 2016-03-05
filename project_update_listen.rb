#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'sinatra'
require 'awesome_print'

require File.dirname(__FILE__) + '/functions.rb'

set :port, 9999
set :bind, '0.0.0.0'

post '/update/:name' do
	#name = /[a-zA-Z]\w*/.match(params[:name])
	name = params[:name]
	dir="/www/"+name	
	if File.directory?(dir) then
		system("cd #{dir}; git pull")
	end
end
before do
	auth_ip = get_auth_ip
	if request.path_info!="/robots.txt" and auth_ip.index(request.ip)== nil then
		halt
	end

end
get "/robots.txt" do
	"User-agent: *\nDisallow: /"
end
not_found do
	""
end
