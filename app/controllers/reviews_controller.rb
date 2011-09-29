class ReviewController < ApplicationController

  def create
    respond_to do |format|
      format.html # index.html.erb
      format.json
      format.js
    end
  end

end
