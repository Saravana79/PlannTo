class Publisher < ActiveRecord::Base

  validates_presence_of :publisher_url

	def self.getpublisherfromdomain(url)
    return nil if url.blank?
		host = URI.parse(url).host.downcase rescue ""
		domain = host.start_with?('www.') ? host[4..-1] : host
		domain = domain.start_with?('blog.') ? domain[5..-1] : domain
		#publisher = Publisher.where(:publisher_url => "sportskeeda.com").first
		publisher = Publisher.where(:publisher_url =>  domain).first

    splted_domain = domain.split(".")
    if publisher.blank? && splted_domain.count > 1
      domain = splted_domain.last(2).join(".")
      publisher = Publisher.where(:publisher_url =>  domain).first
    end
    publisher
	end
end
