class ContentSweeper < ActionController::Caching::Sweeper
observe Content

	def after_create(content)
		Rails.logger.info "***************123******************"
	 	cache_key = "views/#{config.hostname}/cars/5"
	 	Rails.logger.info "***************" + cache_key + "******************"
	 	Rails.logger.info url_for :controller => '/products', :action => 'show', :id => 10 
    	Rails.cache.delete(cache_key)
	 	Rails.logger.info "*******************123************************"
	end

	def after_destroy(contentrelation)
		expire_contents_and_items(contentrelation)	 	
	end


	private 
	def expire_contents_and_items(contentrelation)		
		unless(contentrelation.nil?)
			Rails.logger.info "Cache clear start" + contentrelation.item_id.to_s
			item = Item.find(contentrelation.item_id)
      		expire_action(:controller => '/products', :action => 'show', :id => "5")	
      		#expire_action(:controller => '/contents', :action => 'show', :id => contentrelation.content_id)	
      		Rails.logger.info "Cache clear start" + item.slug
      		Rails.logger.info "Cache clear end" + contentrelation.content_id.to_s
      	end
		
	end 
end