class ItemsController < ApplicationController
  layout "product"
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
 
  include FollowMethods
  #before_filter :authenticate_user!
  # GET /items
  # GET /items.json
  def index
    #@items = Item.all
    #    @items = Car.all
    #
    #    @car = Car.new
    #    @car.name = 'Fiat Grande Punto 2 '
    #    @car.description = 'Grande Punto Version 2'
    #    @car.editablebynonadmin = false
    #    @car.isgroupheader = false
    #    @car.needapproval = false

    #   @car = Car.find :last
    #    @itemtype = Itemtype.find_by_itemtype('Car')
    #  @manufacturer = Manufacturer.find_by_name('Fiat')
    # @accessories = Accessory.find_by_name 'Car'
    # @relatedcars = Car.all

    #  @car.manufacturer = @manufacturer
    #    @car.itemtype = @itemtype


    #@car.itemrelationship.relationtype = 'Manufacturer'
    #@car.accessories = @accessories
    #@car.relatedcars = @relatedcars

    #@car.save
    #    Itemrelationship.create(:item => @car, :relateditem => @manufacturer, :relationtype => "Manufacturer")
    #@rel = Itemrelationship.new #.create(@car,:relationtype => "Manufacturer")
    #@rel.car = @car
    #@rel.manufacturer = @manufacturer
    #@rel.relationtype = 'Manufacturer'
    #@rel.save

    @car = Car.find(5).manufacturer
    
    

#    result = Sunspot.search(Car) do
#      keywords params[:q]
#      facet :manufacturer
#      dynamic :features do
#        #with(:Price).greater_than(1800000)
#        facet(:Price)
#        facet(:Engine)
#        facet(:'Fuel Economy [City]')
#      end
#
#    end
    # if result.facet( :manufacturer )
    #    @facet_rows = result.facet(:manufacturer).rows
    #  end
     
    @items = Car.find(:all, :limit => 10)
    render :layout => 'application'
    #respond_to do |format|
    #  format.html  index.html.erb
    #  format.json { render json: @items }
    # end
  end

  # GET /items/1
  # GET /items/1.json
  def show
    @user = User.last    
    @user.follow_type = 'Buyer'
    @item = Item.where(:id => params[:id]).includes(:item_attributes).last
    @review = Review.new
    @review.pros.build
    @review.cons.build
    @review.best_uses.build
    @comment = Comment.new
    @questions = Question.all
    #logger.warn "Relation Count :: " + @item.relateditems.length.to_s
    #@item = Car.find params[:id]
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @item }
    end if @item
  end

  # GET /items/new
  # GET /items/new.json
  def new
    @item = Item.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item }
    end
  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
  end

  # POST /items
  # POST /items.json
  def create
    @item = Item.new(params[:item])

    respond_to do |format|
      if @item.save
        format.html { redirect_to @item, notice: 'Item was successfully created.' }
        format.json { render json: @item, status: :created, location: @item }
      else
        format.html { render action: "new" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.json
  def update
    @item = Item.find(params[:id])

    respond_to do |format|
      if @item.update_attributes(params[:item])
        format.html { redirect_to @item, notice: 'Item was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item = Item.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to items_url }
      format.json { head :ok }
    end
  end

  def compare
    @static_page1 = "true"
    @ids = params[:ids].split(',') rescue ""
     p = params[:ids].split(',') rescue ''
     unless p == ""
      if p.include?('')
         p.delete('')
        params[:ids] = p.join(",")
      end 
    end 
    unless @ids.blank? || params[:ids] == ""
      @item1 = Item.find(@ids[1]) if @ids[0] == ''
      @item1 = Item.find(@ids[0]) if @ids[0]!= ''
      session[:item_type] =  @item1.get_base_itemtype
      @items = Item.includes(:attribute_values).where("items.id in (?)", @ids)
      logger.info "======================++++++====#{@items}"
      @attribute_ids = @items.collect{|i|i.attribute_values.collect(&:attribute_id)}.flatten.uniq
       @attributes = Attribute.where("id in (?)", @attribute_ids)
      @ids[0] = "0" if @ids[0] == ""
      #content_ids = ItemContentsRelationsCache.find_by_sql("select content_id, count(*) from item_contents_relations_cache INNER JOIN contents ON item_contents_relations_cache.content_id = contents.id where item_id in (#{@ids.join(",")}) and contents.sub_type in ('Reviews','Deals','Lists') group by content_id order by count(*) desc").collect(&:content_id)
      #@contents = Content.where("id in (?)",content_ids).order("total_votes desc")
      @attribute_comparision_lists = AttributeComparisonList.where("itemtype_id = ?",  @item1.itemtype_id).order("sort_order asc")

   else
    
    unless params[:item_type].nil?
      session[:item_type] = params[:item_type] 
     end 
     @item_type = session[:item_type]
   end   
  end

end
