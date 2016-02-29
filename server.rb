# -*- coding: utf-8 -*-

require 'socket'               # 获取socket标准库
 
server = TCPServer.open(9999)  # Socket 监听端口为 2000
loop do                        # 永久运行服务
  Thread.start(server.accept) do |client|
    while line = client.gets # Read lines from socket
      puts line         # and print them
    end
    client.close
  end
end
