@dir = "#{File.expand_path('../../', __FILE__)}"

#worker_processes 2
working_directory @dir

timeout 300
#listen 80
listen "#{@dir}/tmp/unicorn.sock", backlog: 1024 

pid "#{@dir}/tmp/pids/unicorn.pid"

# unicornは標準出力には何も吐かないのでログ出力を忘れずに
stderr_path "#{@dir}/log/unicorn.stderr.log"
stdout_path "#{@dir}/log/unicorn.stdout.log"
