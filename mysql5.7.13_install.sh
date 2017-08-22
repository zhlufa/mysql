#!/bin/bash
if [ `uname -m` == "x86_64" ];then
machine=x86_64
else
machine=i686
fi
cd /usr/local
mysqlBasedir=/usr/local/mysql
mysqlDatadir=/data/mysql_data
mysqlUser=mysql
mysqlGroup=mysql

#卸载
/etc/init.d/mysqld stop
sleep 5
mv /data /data_bak
unlink /usr/local/mysql
mv /etc/my.cnf > /etc/my.cnf_old
#创建my.cnf模板
cat > /etc/my.cnf <<END
#[client]
#user=root
#password=111111

[mysqld]
########basic settings########
#skip-grant-tables
server-id = 1 
port = 3306
user = mysql
#bind_address = 10.139.101.101
#autocommit = 0
character_set_server=utf8mb4
skip_name_resolve = 1
max_connections = 800
max_connect_errors = 1000
basedir = /usr/local/mysql
datadir = /data/mysql_data
transaction_isolation = READ-COMMITTED
explicit_defaults_for_timestamp = 1
join_buffer_size = 134217728
tmp_table_size = 67108864
tmpdir = /tmp
max_allowed_packet = 16777216
sql_mode = "STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER"
interactive_timeout = 1800
wait_timeout = 1800
read_buffer_size = 16777216
read_rnd_buffer_size = 33554432
sort_buffer_size = 33554432

########log settings########
log_error = error.log
slow_query_log = 1
slow_query_log_file = slow.log
log_queries_not_using_indexes = 1
log_slow_admin_statements = 1
log_slow_slave_statements = 1
log_throttle_queries_not_using_indexes = 10
expire_logs_days = 90
long_query_time = 2
min_examined_row_limit = 100

########replication settings########
master_info_repository = TABLE
relay_log_info_repository = TABLE
log_bin = bin.log
sync_binlog = 1
gtid_mode = on
enforce_gtid_consistency = 1
log_slave_updates
binlog_format = row 
relay_log = relay.log
relay_log_recovery = 1
binlog_gtid_simple_recovery = 1
slave_skip_errors = ddl_exist_errors

########innodb settings########
innodb_page_size = 8192
innodb_buffer_pool_size = 3G
innodb_buffer_pool_instances = 2
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_lru_scan_depth = 2000
innodb_lock_wait_timeout = 5
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_flush_method = O_DIRECT
innodb_file_format = Barracuda
innodb_file_format_max = Barracuda
#innodb_log_group_home_dir = /redolog/
#innodb_undo_directory = /undolog/
innodb_undo_logs = 128
innodb_undo_tablespaces = 3
innodb_flush_neighbors = 1
innodb_log_file_size = 4G
innodb_log_buffer_size = 16777216
innodb_purge_threads = 4
innodb_large_prefix = 1
innodb_thread_concurrency = 64
innodb_print_all_deadlocks = 1
innodb_strict_mode = 1
innodb_sort_buffer_size = 67108864 

########semi sync replication settings########
plugin_dir=/usr/local/mysql/lib/plugin
plugin_load = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
loose_rpl_semi_sync_master_enabled = 1
loose_rpl_semi_sync_slave_enabled = 1
loose_rpl_semi_sync_master_timeout = 5000

[mysqld-5.7]
innodb_buffer_pool_dump_pct = 40
innodb_page_cleaners = 4
innodb_undo_log_truncate = 1
innodb_max_undo_log_size = 2G
innodb_purge_rseg_truncate_frequency = 128
binlog_gtid_simple_recovery=1
log_timestamps=system
transaction_write_set_extraction=MURMUR32
show_compatibility_56=on

[mysqld2]
server-id=2
port=3307
datadir=/data/mysql_data2
socket=/tmp/mysql.sock2

[mysqld3]
server-id=3
port=3308
datadir=/data/mysql_data3
socket=/tmp/mysql.sock3
basedir=/data/mysql_data3
END
if [ $machine == "x86_64" ];then
	#创建data文件
	mkdir -p $mysqlDatadir
	#添加mysql用户组
	groupadd $mysqlGroup
	#添加mysql用户 ,并制定组为mysql /sbin/nologin意思是用户不允许登录
	useradd -g $mysqlGroup -s /sbin/nologin $mysqlUser
	#设置权限
	chown -R ${mysqlUser}:${mysqlGroup} $mysqlBasedir
	chown -R ${mysqlUser}:${mysqlGroup} $mysqlDatadir
	#下载解压初始化安装
	if [ ! -f mysql-5.7.18-linux-glibc2.5-x86_64.tar.gz ];then
		wget http://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.18-linux-glibc2.5-x86_64.tar.gz
	fi
		tar -xzvf mysql-5.7.18-linux-glibc2.5-x86_64.tar.gz
		ln -s /usr/local/mysql-5.7.18-linux-glibc2.5-x86_64 /usr/local/mysql
	else
	echo 'error ：你的系统不是64位？'
fi
#添加mysql用户组
groupadd $mysqlGroup
#添加mysql用户 ,并制定组为mysql /sbin/nologin意思是用户不允许登录
useradd -g $mysqlGroup -s /sbin/nologin $mysqlUser
#设置权限
chown -R ${mysqlUser}:${mysqlGroup} $mysqlBasedir
chown -R ${mysqlUser}:${mysqlGroup} $mysqlDatadir
#安装服务
${mysqlBasedir}/bin/mysqld --initialize
#添加环境变量
echo 'PATH=$PATH:/usr/local/mysql/bin
export PATH'>>/etc/profile
source /etc/profile
echo $PATH
#加入开机启动
cp ${mysqlBasedir}/support-files/mysql.server /etc/init.d/mysqld
chmod 755 /etc/init.d/mysqld
#启动
/etc/init.d/mysqld start
#by:M95-zhlufa 20160712