module Reputation

  #class Unauthorized < StandardError; end

  def self.included(base)
    base.send(:include, Reputation::ControllerMethods)
  end

  module ControllerMethods

  	def update_user_reputation(user,points_details,add_reputation = true)
  		if points_details[:self_update] || user != current_user
  			user.reputation += add_reputation ? points_details[:points] : -(points_details[:points])
  			user.save 
  		end
  	end

		def reputation_tester
			current_user.nil?
		end	
  end

end