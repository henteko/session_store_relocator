require 'redis-session-store'

module SessionStoreRelocator
  class CookieToRedis < ActionDispatch::Session::CookieStore
    def initialize(app, options = {})
      super(app, options[:cookie_store])
      @redis_session_store = RedisSessionStore.new(app, options[:redis_session_store])
      @options = options
    end

    def destroy_session(*args)
      super.tap do
        @redis_session_store.send(:destroy_session, *args)
      end
    end

    def commit_session(*args)
      @redis_session_store.send(:commit_session, *args)
    end

    def load_session(*args)
      key = @options[:redis_session_store][:key]
      env = args.first
      sid = env['rack.request.cookie_hash'][key]

      session = @redis_session_store.send(:get_session, sid)
      return session unless session.nil?

      super
    end
  end
end
