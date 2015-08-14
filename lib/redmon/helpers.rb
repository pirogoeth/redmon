module Redmon
  module Helpers
    include Redmon::Redis

    def protected!
      return if authorized? or not Redmon.config.secure
      headers['WWW-Authenticate'] = 'Basic realm="Redmon"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == Redmon.config.secure.split(':')
    end

    def prompt
      "#{redis_url.gsub('://', ' ')}>"
    end

    def poll_interval
      Redmon.config.poll_interval * 1000
    end

    def num_samples_to_request
      (Redmon.config.data_lifespan * 60) / Redmon.config.poll_interval
    end

    def count
      -(params[:count] ? params[:count].to_i : 1)
    end

    def absolute_url(path='')
      "#{uri(nil, false)}#{path.sub(%r{^\/+}, '')}"
    end

  end
end
