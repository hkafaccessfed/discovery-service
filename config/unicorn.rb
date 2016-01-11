ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'unicorn-prewarm'

worker_processes 8
preload_app true
pid File.join(ROOT, 'tmp', 'pids', 'unicorn.pid')
stdout_path '/var/log/aaf/discovery/unicorn/stdout.log'
stderr_path '/var/log/aaf/discovery/unicorn/stderr.log'

before_fork do |server, _worker|
  # Prewarm the Sprockets asset index
  get = Net::HTTP::Get.new('/discovery')
  fake = Unicorn::Prewarm::FakeSocket.new(get)
  server.send(:process_client, fake)
  fake.response.value

  old_pid = File.join(ROOT, 'tmp', 'pids', 'unicorn.pid.oldbin')
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      :not_running
    end
  end
end

# Override Unicorn's process name to include the application name.
class Unicorn::HttpServer # rubocop:disable ClassAndModuleChildren
  def proc_name(tag)
    $0 = ([File.basename(START_CTX[0]), 'discovery',
           tag]).concat(START_CTX[:argv]).join(' ')
  end
end
