upstream {appname} {
    server 127.0.0.1:{port};
}

server {
    listen 80;
    server_name {server_name};

    root   html;
    index  index.html index.htm index.php;
    location / {
        proxy_pass  http://{appname};

        #Proxy Settings
        proxy_redirect     off;
        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_max_temp_file_size 0;
        proxy_connect_timeout      90;
        proxy_send_timeout         90;
        proxy_read_timeout         90;
        proxy_buffer_size          4k;
        proxy_buffers              4 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
   }
   location ~* ^.+\.(js|css|ico|gif|jpg|jpeg|png|html|htm|woff|svg|ttf|eot)$ {
        proxy_pass   http://{appname};
                log_not_found off;
                access_log off;
                expires 365d;
   }
}
