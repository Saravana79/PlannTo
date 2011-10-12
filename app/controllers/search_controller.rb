class SearchController < ApplicationController

  def search_items
    @page  = params[:page].nil? ? 1 : params[:page].to_i

    @items = Sunspot.search(Manufacturer,CarGroup ) do
      keywords params[:q]
      paginate(:page => params[:page], :per_page => 10)
      # order_by :itemtype_id, :asc
    end
    if @items.results.count < 10
      @display = "none;"
    else
      @display = "block;"
      @page += 1
    end

  end


  def autocomplete_items
    @items = Sunspot.search(Manufacturer,CarGroup) do
      keywords params[:term], :fields => :name 
      order_by :class, :desc
      paginate(:page => 1, :per_page => 6)
      # order_by :itemtype_id, :asc
    end
    

    #    @results  = Array.new
    #    @items.results.each do |item|
    #      logger.info(item.attributes)
    #      if item.cargroup.nil?
    #        @results  << {:id => item.id, :value => "#{item.name}", :imgsrc => "/images/B16.jpg", :header => false }
    #      else
    #        @added  =false
    #          @results.each do |result|
    #            if result[:id] == item.cargroup.id
    #               result[:children] << {:id => item.id, :value => "#{item.name}", :imgsrc => "/test/B16.jpg", :header => false }
    #              @added  = true
    #            end
    #          end
    #        @results  << {:id => item.cargroup.id, :value => "#{item.cargroup.name}", :imgsrc => "/images/B16.jpg", :header => true, :children => [{:id => item.id, :value => "#{item.name}", :imgsrc => "/images/B16.jpg", :header => false }]} if @added == false
    #      end
    #    end
    render :json => @items.results.collect{|item| {:id => item.id, :value => "#{item.name}", :imgsrc => "/images/B16.jpg" }}
  end
end
