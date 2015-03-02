class Publisher < ActiveRecord::Base

	def self.getpublisherfromdomain(url)
		host = URI.parse(url).host.downcase rescue ""
		domain = host.start_with?('www.') ? host[4..-1] : host
		domain = domain.start_with?('blog.') ? domain[5..-1] : domain
		publisher = Publisher.where(:publisher_url => "sportskeeda.com").first
	end
end
