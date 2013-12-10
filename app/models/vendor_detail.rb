class VendorDetail < ActiveRecord::Base
  belongs_to :item

 	def self.getdomain(url)
		host = URI.parse(url).host.downcase rescue ""
		domain = host.start_with?('www.') ? host[4..-1] : host	
		domain = domain.start_with?('offers.') ? domain[7..-1] : domain      	
	end
end
