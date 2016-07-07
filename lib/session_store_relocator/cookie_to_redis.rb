require 'redis-session-store'

module SessionStoreRelocator
  class CookieToRedis < RedisSessionStore
    def initialize(app, options = {})
      super(app, options[:redis_session_store])
      @cookie_store = ActionDispatch::Session::CookieStore.new(app, options[:cookie_store])
    end

    def destroy_session(*args)
      super.tap do
        @cookie_store.send(:destroy_session, *args)
      end
    end

    def get_session(*args)
      env = args.first
      session = @cookie_store.send(:load_session, env)
      data = session.last
      data.delete('session_id')
      unless data.empty?
        @cookie_store.send(:destroy_session, *(args.push({})))
        return session
      end

      super
    end
  end
end
