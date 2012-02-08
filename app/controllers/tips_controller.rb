class TipsController < ApplicationController

	def create
		@tip = Tip.new(params[:tip])
		@tip.user = User.first


		if @tip.save
			respond_to do |format|
				format.html
				format.js 
			end
			
		end
	end	
end
