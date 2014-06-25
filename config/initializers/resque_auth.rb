Resque::Server.use(Rack::Auth::Basic) do |_, password|
  password == "plannto@123"
end