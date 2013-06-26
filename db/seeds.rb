# This file should contain all the record creation needed to seed the database with its default value1s.
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
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 108,condition: "Between",  value1: ".99", value2: ".55", title: "Average Processor Speed", proorcon: "Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 108,condition: "Lesser",  value1:".55", value2:"", title: "Less than Average Processor Speed", proorcon: "Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 117,condition: "Greater",  value1:"0.425", value2:"", title: "Larger Screen", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 117,condition: "Equal",  value1:"3.5", value2:"", title: "Smaller Screen", proorcon: "Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 132, condition: "Lesser", value1:"True", value2:"", title:"Supports Dual Sim",:description: "You can have two SIM cards in same mobile", proorcon: "Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 104,condition: "Greater",  value1:"1", value2:"", title:"Doesn't Support External Storage", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 104,condition: "Greater",  value1:"1", value2:"", title: "Supports External Storage", proorcon:"Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 106,condition: "Lesser",  value1:"7", value2:"", title:"Good internal storage capacity", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 106,condition: "Lesser",  value1:"5", value2:"", title:"Less internal storage capacity", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 101, condition: "Greater", value1:"100", value2:"", title: "Lighter", proorcon: "Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 101,condition: "Lesser",  value1:"150", value2:"", title: "Heavier", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 99,condition: "Greater",  value1:".12", value2:"", title: "Thinner Mobile", proorcon: "Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 102,condition: "Lesser",  value1:"1", value2:"", title: "More RAM", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 102,condition: "Greater",  value1:"1", value2:"", title:"Lesser than average RAM", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 102,condition: "Lesser",  value1:"6", value2:"", title:"Good Talk Time", proorcon: "Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 110,condition: "Greater",  value1:"5", value2:"", title: "Lesser than average TalkTime", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 110,condition: "Greater",  value1:"800", value2:"", title: "Longer Standby Time", proorcon:"Con")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 111,condition: "Equal",  value1:"True", value2: "", title:"Supports Touchscreen",:description: "Use fingers to access menus and features", proorcon: "Pro")
ItemSpecificationSummaryList.create(itemtype_id: 6, attribute_id: 114, condition: "Not Equal", value1:"True", value2:"", title:"Doesn't support Touchscreen",:description: "Only buttons can be used for accessing menus", proorcon:"Pro")
