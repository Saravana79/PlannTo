class ItemsController < ApplicationController
  before_filter :find_item, :only => [:edit, :update, :destroy]
#  caches_action :compare ,:cache_path => Proc.new { |c| 
#   unless c.params[:ids].nil? 
#     "compare/" + c.params[:ids].split(",").sort.join(",")
#   else
#    c.params
#   end
#     },:expires_in => 2.hour
  layout "product"
  before_filter :authenticate_user!, :except => [:index, :compare]

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
    @item = Item.where(:slug => params[:id]).includes(:item_attributes).last
    unless @item.blank?
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
    else
      redirect_to update_page_items_path
    end
  end

# GET /items/new
# GET /items/new.json
  def new
    @item = Item.new(:status => "1")
    @item_types = Itemtype.select("id,itemtype")
    @action = "/items/create"

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item }
    end
  end

# GET /items/1/edit
  def edit
    if @item.blank?
      flash_msg = {:alert => "Item Not Available"}

      respond_to do |format|
        format.html { redirect_to update_page_items_path,  flash_msg}
        format.json { head :ok }
      end
    else
      @item_types = Itemtype.select("id,itemtype")
      @action = "/items/update/#{@item.id}"
    end
  end

# POST /items
# POST /items.json
  def create
    image = params[:upload_image]
    p image
    params[:item][:imageurl] = image.original_filename if !image.blank?

    @item_types = Itemtype.select("id,itemtype")
    itemtype = Itemtype.where("id = ?", params[:item][:itemtype_id]).first
    klass = itemtype.itemtype.to_s.gsub(" ", "")

    @item = klass.constantize.new(params[:item].merge(:created_by => current_user.id))

    respond_to do |format|
      if @item.save
        if (!params[:manufacturer_id].blank?)
          Itemrelationship.create(:item_id => @item.id, :relateditem_id => params[:manufacturer_id], :relationtype => "Manufacturer")
        end
        if (!params[:item][:group_id].blank?)
          Itemrelationship.create(:item_id => @item.id, :relateditem_id => params[:item][:group_id], :relationtype => "CarGroup")
        end
        if (!params[:parent_id].blank?)
          Itemrelationship.create(:item_id => @item.id, :relateditem_id => params[:parent_id], :relationtype => "Parent")
        end

        if !image.blank?
          @image = @item.build_image
          @image.avatar = image
          @image.save!
        end

        format.html { redirect_to new_item_path, notice: 'Item was successfully created.' }
        format.json { render json: @item, status: :created, location: @item }
      else
        @item.imageurl = '' if !image.blank?
        @item.valid?
        format.html { render action: "new" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

# PUT /items/1
# PUT /items/1.json
  def update
    if @item.blank?
      flash_msg = {:alert => "Item is not available"}
    else
      @item_types = Itemtype.select("id,itemtype")
      @action = "/items/update/#{@item.id}"
      p image = params[:upload_image]

      if @item.update_attributes(params[:item])
        item_type = Itemtype.where("id = ?", params[:item][:itemtype_id]).first
        @item.type = item_type.itemtype
        @item.save!
        if (!params[:manufacturer_id].blank?)
          manufacturer = Itemrelationship.where(:item_id => @item.id, :relationtype => "Manufacturer").last
          manufacturer.destroy unless manufacturer.blank?
          Itemrelationship.create(:item_id => @item.id, :relateditem_id => params[:manufacturer_id], :relationtype => "Manufacturer")
        end
        if (!params[:item][:group_id].blank?)
          group = Itemrelationship.where(:item_id => @item.id, :relationtype => "CarGroup").last
          group.destroy unless group.blank?
          Itemrelationship.create(:item_id => @item.id, :relateditem_id => params[:item][:group_id], :relationtype => "CarGroup")
        end
        if (!params[:parent_id].blank?)
          group = Itemrelationship.where(:item_id => @item.id, :relationtype => "Parent").last
          group.destroy unless group.blank?
          Itemrelationship.create(:item_id => @item.id, :relateditem_id => params[:parent_id], :relationtype => "Parent")
        end

        if !image.blank?
          @item.image ? @item.image.destroy : ""
          @image = @item.build_image
          @image.avatar = image
          @image.save!
        end
        flash_msg = {notice: 'Item was successfully updated.'}
      end
    end


      respond_to do |format|
        if @item.blank? || @item.valid?
          format.html { redirect_to update_page_items_path, flash_msg }
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
      if @item.blank?
        flash_msg = {:alert => "Item Not Available"}
      else
        @item.destroy
        flash_msg = {:notice => "Item Successfully Deleted"}
      end

      respond_to do |format|
        format.html { redirect_to update_page_items_path, flash_msg }
        format.json { head :ok }
      end
    end

    def compare
      @static_page1 = "true"
      @ids = params[:ids].split(',').uniq rescue ""
      p = params[:ids].split(',').uniq rescue ''
      unless p == ""
        if p.include?('')
          p.delete('')
          params[:ids] = p.join(",")
        end
      end


      unless @ids.blank? || params[:ids] == ""
        related_item_ids = RelatedItem.where('item_id in (?)',p).order(:variance).limit(10).collect(&:related_item_id)
        @related_items = Item.where('id in (?) and id not in (?)' ,related_item_ids,  p).order("id desc")
        @items = Item.includes([:attribute_values => :attribute],:item_rating).where("items.id in (?)", p)

        @item1 = @items[0]
        session[:item_type] =  @item1.get_base_itemtype
        logger.info "======================++++++====#{@items}"
        #   @attribute_ids = @items.collect{|i|i.attribute_values.collect(&:attribute_id)}.flatten.uniq
        @attributes = @items.collect(&:attribute_values).flatten.uniq.collect{|av| av.attribute}.flatten.uniq.compact
        @attribute_ids = @attributes.collect(&:id)
        @ids[0] = "0" if @ids[0] == ""
        content_ids = ItemContentsRelationsCache.find_by_sql("select content_id, count(*) from item_contents_relations_cache INNER JOIN contents ON item_contents_relations_cache.content_id = contents.id where item_id in (#{p.join(",")}) and contents.sub_type in ('Comparisons') group by content_id having count(*) > 1 limit 15").collect(&:content_id)
        @contents = Content.where("id in (?)",content_ids).order("total_votes desc")
        @attribute_comparision_lists = AttributeComparisonList.where(:itemtype_id => @item1.itemtype_id).order("sort_order")

      else

        unless params[:item_type].nil?
          session[:item_type] = params[:item_type]
        end
        @item_type = session[:item_type]
      end
    end

    def update_page

    end

    private

    def find_item
      begin
        @item = Item.find(params[:id])
      rescue
        @item = nil
      end
    end

  end
