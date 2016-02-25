# -*- coding: utf-8 -*-

require 'awesome_print'
require 'docker'

arg0 =  ARGV[0]
Docker.url='unix:///var/run/docker.sock'


if arg0 == "image" then
	images = Docker::Image.all
	images.each do |img|
		printf("%-15s %-15s %-15s\n", img.id.split(":")[1][0,12], img.info['RepoTags'][0], (img.info['Size']/1000000.0).round(2).to_s+"M")
	end
end

