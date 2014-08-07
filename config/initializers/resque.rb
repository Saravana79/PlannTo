module Resque
  class Worker
    alias :original_reserve :reserve
    def reserve( *args )
      unless Resque.redis.get("resque_paused") == "true"
        self.original_reserve *args
      end
    end
  end
end