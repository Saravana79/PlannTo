class ItemrelationshipsController < ApplicationController
  # GET /itemrelationships
  # GET /itemrelationships.json
  def index
    @itemrelationships = Itemrelationship.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @itemrelationships }
    end
  end

  # GET /itemrelationships/1
  # GET /itemrelationships/1.json
  def show
    @itemrelationship = Itemrelationship.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @itemrelationship }
    end
  end

  # GET /itemrelationships/new
  # GET /itemrelationships/new.json
  def new
    @itemrelationship = Itemrelationship.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @itemrelationship }
    end
  end

  # GET /itemrelationships/1/edit
  def edit
    @itemrelationship = Itemrelationship.find(params[:id])
  end

  # POST /itemrelationships
  # POST /itemrelationships.json
  def create
    @itemrelationship = Itemrelationship.new(params[:itemrelationship])

    respond_to do |format|
      if @itemrelationship.save
        format.html { redirect_to @itemrelationship, notice: 'Itemrelationship was successfully created.' }
        format.json { render json: @itemrelationship, status: :created, location: @itemrelationship }
      else
        format.html { render action: "new" }
        format.json { render json: @itemrelationship.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /itemrelationships/1
  # PUT /itemrelationships/1.json
  def update
    @itemrelationship = Itemrelationship.find(params[:id])

    respond_to do |format|
      if @itemrelationship.update_attributes(params[:itemrelationship])
        format.html { redirect_to @itemrelationship, notice: 'Itemrelationship was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @itemrelationship.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /itemrelationships/1
  # DELETE /itemrelationships/1.json
  def destroy
    @itemrelationship = Itemrelationship.find(params[:id])
    @itemrelationship.destroy

    respond_to do |format|
      format.html { redirect_to itemrelationships_url }
      format.json { head :ok }
    end
  end
end
