PumaWorkerKiller.config do |config|
  config.ram           = 512 # mb
  config.frequency     = 5    # seconds
  config.percent_usage = 0.98
  config.rolling_restart_frequency = false # 12 * 3600 for 12 hours in seconds
end
PumaWorkerKiller.start