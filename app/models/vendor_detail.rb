class VendorDetail < ActiveRecord::Base
  belongs_to :item

 	def self.getdomain(url)
		host = URI.parse(url).host.downcase rescue ""
		domain = host.start_with?('www.') ? host[4..-1] : host		
	end
end
