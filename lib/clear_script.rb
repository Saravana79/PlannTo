p 22222222222222222222
p Rails.env
Resque.workers.each {|w| w.unregister_worker}