class SearchController < ApplicationController

  def index
    @page  = params[:page].nil? ? 1 : params[:page].to_i
    @manufacturer  = params[:manufacturer].blank? ? "" : params[:manufacturer]
    @min_price = params[:min_price].blank? ? '' : params[:min_price]
    @max_price = params[:max_price].blank? ? '' : params[:max_price]
    @fuel_type = params[:fuel_type].blank? ? "" : params[:fuel_type]

    @items = Sunspot.search(Car) do
      #keywords "Aston", :fields => :name
      with :manufacturer, params[:manufacturer] if !params[:manufacturer].blank?
      facet :manufacturer
      dynamic :features do                
        with(:Price).greater_than(params[:min_price]) if !params[:min_price].blank?
        with(:Price).less_than(params[:max_price]) if !params[:max_price].blank?        
        # with(:'Fuel Economy [City]', 12.4)
        facet(:Engine)
        facet(:'Fuel Economy [City]')      
      end

      dynamic :features_string do
        with('Fuel Type'.to_sym, params[:fuel_type]) if !params[:fuel_type].blank?
      end

      paginate(:page => params[:page], :per_page => 10)
    end
    #order_by :class , :desc    

    @min_price = 2500000 if @min_price.blank?
    @max_price = 5000000 if @max_price.blank?
    @petrol  = true if @fuel_type == "Petrol"
    @diesel = true if @fuel_type == "Diesel"
    @both  = true if @fuel_type == ""

    if @items.results.count < 10
      @display = "none;"
    else
      @display = "block;"
      @page += 1
    end

  end

  def search_items
    @page  = params[:page].nil? ? 1 : params[:page].to_i

    @items = Sunspot.search(Manufacturer,CarGroup ) do
      keywords params[:q], :fields => :name
       order_by :class, :desc
      paginate(:page => params[:page], :per_page => 10)
      #facet :types
      order_by :class , :desc
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
      order_by :class , :desc
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
    render :json => @items.results.collect{|item| {:id => item.id, :value => "#{item.name}", :imgsrc => "/images/B16.jpg", :type => item.type.humanize }}
  end

  def autocomplete_manufacturers
    @items = Sunspot.search(Manufacturer) do
      keywords params[:term], :fields => :name
      #paginate(:page => 1, :per_page => 6)
    end

    render :json => @items.results.collect{|item| {:id => item.id, :value => "#{item.name}"}}
  end
end
