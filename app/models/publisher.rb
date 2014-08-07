class Publisher < ActiveRecord::Base

	def self.getpublisherfromdomain(url)
		host = URI.parse(url).host.downcase rescue ""
		domain = host.start_with?('www.') ? host[4..-1] : host
		domain = host.start_with?('blog.') ? host[5..-1] : host
		publisher = Publisher.where(:publisher_url => domain).first 
	end
end
