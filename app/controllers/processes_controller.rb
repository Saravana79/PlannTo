require 'rake'
Rake::Task.clear # necessary to avoid tasks being loaded several times in dev mode
PlanNto::Application.load_tasks

class ProcessesController < ApplicationController
  before_filter :authenticate_admin_user!
  layout "product"
  def index

  end

  def item_update
    Rake::Task["item_update"].invoke
    flash[:notice] = "successfully Initiated Item Update Process"
    redirect_to processes_path
  end
end
