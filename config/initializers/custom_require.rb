%w{custom_acts_as_follower authentication reputation ext/string addressable/uri}.each { |each_val| require each_val }

require "#{Rails.root}/lib/heroku_resque_auto_scale.rb"