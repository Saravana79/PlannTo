class EventContentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @event_content = EventContent.new params[:event_content]
		@event_content.user = current_user
		Content.transaction do
	    if @event_content.save     
        item = Item.find(params[:item_id])
        rel= ContentItemRelation.new(:item => item, :content => @event_content)
        rel.save!
      end
    end

  end
end
