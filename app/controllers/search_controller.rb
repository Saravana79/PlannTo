class SearchController < ApplicationController

  def search_items
    @page  = params[:page].nil? ? 1 : params[:page].to_i

    @items = Sunspot.search(Car) do
      keywords params[:q]
      paginate(:page => params[:page], :per_page => 10)
      # order_by :itemtype_id, :asc
    end
    @items.results.count < 10 ? @page = 1 : @page += 1

  end


  def autocomplete_items
    @items = Sunspot.search(Car) do
      keywords params[:term]
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
