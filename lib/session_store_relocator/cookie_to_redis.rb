require 'redis-session-store'

module SessionStoreRelocator
  class CookieToRedis < RedisSessionStore
    def initialize(app, options = {})
      super(app, options[:redis_session_store])
      @cookie_store = CookieStore.new(app, options[:cookie_store])
    end

    def destroy_session(*args)
      super.tap do
        @cookie_store.send(:destroy_session, *args)
      end
    end

    def get_session(*args)
      env = args.first
      session_id = args.last

      session = session_class.new(@cookie_store, env)
      data = session.to_hash.clone
      data.delete('session_id')
      unless data.empty?
        result = session.to_hash
        set_session(env, session_id, result)
        session.destroy
        return [session_id, result]
      end

      super
    end
  end

  class CookieStore < ActionDispatch::Session::CookieStore
    def initialize(app, options = {})
      super(app, options)
    end

    def destroy_session(*args)
      env = args.first
      session_id = args.second
      set_cookie(env, session_id, {})
    end
  end
end
