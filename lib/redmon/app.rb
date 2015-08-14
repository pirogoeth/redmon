require 'sinatra/base'
require 'sinatra/namespace'
require 'redmon/helpers'
require 'redis'
require 'haml'

module Redmon
  class App < Sinatra::Base
    register Sinatra::Namespace

    helpers Redmon::Helpers

    set :root, File.dirname(__FILE__)
    set :views, Proc.new { File.join(root, "./views") }

    use Rack::Static, {
      :urls => [/\.css$/, /\.js$/],
      :root => "#{root}/public",
      :cache_control => 'public, max-age=3600'
    }

    get '/' do
      protected!
      haml :app
    end

    get '/health/app' do
      'okay'
    end

    get '/health/redis' do
      begin
        @result = redis.send "ping"
        @result = empty_result if @result == []
        if @result != "PONG"
          "not okay"
        else
          "okay"
        end
      rescue ::Redis::CannotConnectError
        "not okay"
      rescue
        "unknown"
      end
    end

    get '/cli' do
      protected!
      args = params[:command].split(/ *"(.*?)" *| *'(.*?)' *| /)
      args.reject!(&:empty?)
      @cmd = args.shift.downcase.intern
      begin
        raise RuntimeError unless supported? @cmd
        @result = redis.send @cmd, *args
        @result = empty_result if @result == []
        haml :cli
      rescue ArgumentError
        wrong_number_of_arguments_for @cmd
      rescue RuntimeError
        unknown @cmd
      rescue Errno::ECONNREFUSED
        connection_refused
      end
    end

    post '/config' do
      protected!
      param = params[:param].intern
      value = params[:value]
      redis.config(:set, param, value) and value
    end

    get '/stats' do
      protected!
      content_type :json
      redis.zrange(stats_key, count, -1).to_json
    end

  end
end
