class ContentsController < ApplicationController

  layout :false
  def feed
    
    @contents = Content.filter(params.slice(:items, :type, :order, :limit, :page))
    
     respond_to do |format|
       format.html { render "feed", :locals => {:params => params} }
        format.js { render "feed", :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }}
      end 
  end

end
