class ItemsController < ApplicationController
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item]

  #  before_filter :authenticate_user!
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
     
    @items = {}
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

  def follow_item_type
    case params[:follow_type]
      when 'Buyer'
        plan_to_buy_item
      when 'Owner'
        own_a_item
      when 'Follow'
        follow_this_item
    end
    if params[:follow_type] == 'Buyer'
      plan_to_buy_item
    end
  end

  def plan_to_buy_item
    @type = "buy"
    follow = follow_item(params[:follow_type])
    if follow.blank?
      flash[:notice] = "You already buy this Item"      
    else
      flash[:notice] = "Planning is saved"
    end
    respond_to do |format|
      format.js { }
    end
  end

  def own_a_item
    @type = "own"
    follow = follow_item(params[:follow_type])
    if follow.blank?
      flash[:notice] = "You are already owning this Item"
    else
      flash[:notice] = "Owner is saved"
    end
    respond_to do |format|
      format.js { render :action => 'plan_to_buy_item'}
    end
  end

  def follow_this_item
    @type = "follow"
    follow = follow_item(params[:follow_type])
    if follow.blank?
      flash[:notice] = "You are already Following this Item"
    else
      flash[:notice] = "Follow is saved"
    end
    respond_to do |format|
      format.js { render :action => 'plan_to_buy_item'}
    end
  end

  def compare
    ids = params[:ids].split(',')
    @items = Item.find_all_by_id(ids)
  end

  private

  def follow_item(follow_type)
    Rails.cache.delete("item_follow"+current_user.id.to_s)
    @item = Item.find(params[:id])
    if !@item.blank?
      current_user.follow(@item, follow_type)
    else
      false
    end

  end

end
