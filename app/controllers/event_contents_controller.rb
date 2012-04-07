class EventContentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @event_content = EventContent.new params[:event_content]
    if params[:event_content][:start_date] != ""
    start_date = Date.strptime(params[:event_content][:start_date], "%m/%d/%Y")
    @event_content.start_date = start_date.to_datetime
    end
    if params[:event_content][:end_date] != ""
    end_date = Date.strptime(params[:event_content][:end_date], "%m/%d/%Y")     
    @event_content.end_date = end_date.to_datetime
    end
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
