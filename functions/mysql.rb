require 'mysql2'
require 'json'

def get_mysql_client
	begin
    	config = parse_json_file("mysql_config")
		client = Mysql2::Client.new(
			host: config["host"],
	    	username: config["user"],
			password: config["password"],
			connect_timeout: 10
		)
		client
	rescue => e
		puts e.to_s
		nil
	end
end

def create_user(host, user, password)
	client = get_mysql_client
	sql="insert into mysql.user(Host,User,Password) values('#{host}','#{user}',password('#{password}'))"
	results = client.query(sql)
	client.query("flush privileges")
end

def delete_user(user, host)
	if user and host then
		sql = "delete from mysql.user where user='#{user}' and host='#{host}'"
		get_mysql_client.query(sql)
		get_mysql_client.query("flush privileges")
	end
end

def create_db(dbname, user)
	client = get_mysql_client
	sql = "create database #{dbname}"
	client.query(sql)

	if user then
    	sql="grant all privileges on #{dbname}.* to #{user}@'%'"
		client.query(sql)
	end
end

def delete_db(dbname)
	client = get_mysql_client
	sql = "drop database #{dbname}"
	client.query(sql)
end

def users
	client = get_mysql_client
	result = client.query("select user,host from mysql.user");

	result.each do |row|
  		p row
  	end
end

