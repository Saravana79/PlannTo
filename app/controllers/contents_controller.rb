class ContentsController < ApplicationController

  layout :false
  def feed
    @lks=params[:lks] if !params[:lks].blank?
    @contents = Content.filter(params.slice(:items, :type, :order, :limit, :page))
  end
end
