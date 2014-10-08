class Admin::SourceCategoriesController < ApplicationController

  layout "product"

  def index

  end

  def edit
    @source_category = SourceCategory.where(:source => params[:source]).last
    @categories = ["Mobile", "Tablet", "Camera", "Games", "Laptop", "Car", "Bike", "Cycle"]
    # render :js => "<%= escape_javascript(render :partial => 'admin/source_categories/edit').html_safe %>"
    render :partial => 'admin/source_categories/edit'
  end

  def update
    @source_category = SourceCategory.where(:id => params[:id]).last
    params[:source_category][:categories] = params[:source_category][:categories].join(",")
    @source_category.update_attributes!(params[:source_category])
    redirect_to admin_source_categories_path
  end
end
