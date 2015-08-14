require 'redmon'
require 'redmon/app'
require 'sinatra/base'

begin
  require './config.rb'
rescue LoadError => e
  nil
end

def run_worker!
  if EM.reactor_running?
    Redmon::Worker.new.run!
  else
    fork do
      trap('INT') { EM.stop }
      trap('TERM') { EM.stop }
      EM.run { Redmon::Worker.new.run! }
    end
  end
end

map '/' do
  run_worker!
  run Redmon::App
end

if Redmon.config.base_path != '/'
  map Redmon.config.base_path do
    run_worker!
    run Redmon::App
  end
end
