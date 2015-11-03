git status

rails runner "eval(File.read 'lib/clear_script.rb')"
echo "Stopeed rails console"
Rails.env

# Resque.workers.each {|w| w.unregister_worker}

# git push heroku master
# heroku ps