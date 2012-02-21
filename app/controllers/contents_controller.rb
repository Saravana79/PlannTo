class ContentsController < ApplicationController
  layout :false
  def feed
    @contents = Content.filter(params.slice(:items, :type, :order, :limit))
  end
end

