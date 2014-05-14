class Publisher < ActiveRecord::Base

	def self.getpublisherfromdomain(url)
		host = URI.parse(url).host.downcase rescue ""
		p domain = host.start_with?('www.') ? host[4..-1] : host
		publisher = Publisher.where(:publisher_url => domain).first 
	end
end
