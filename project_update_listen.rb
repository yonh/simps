#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'sinatra'

set :port, 9999
set :bind, '0.0.0.0'

get '/update/:name' do
	#name = /[a-zA-Z]\w*/.match(params[:name])
	name = params[:name]
	dir="/www/"+name	
	if File.directory?(dir) then
		system("cd #{dir}; git pull")
	end
end
not_found do
	""
end
