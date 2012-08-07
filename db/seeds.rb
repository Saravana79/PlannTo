# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#share_type = ShareType.create([{ name: 'Tips' }, { name: 'Review' },{name: 'Q&A'},{name: 'Support'}])

if User.where(:email => "admin@plannto.com").first.blank?
  u = User.new(:password => "adminplannto123", :password_confirmation => "adminplannto123", :email => "admin@plannto.com")
  u.is_admin = true
  u.name = "admin"
  u.save
end

