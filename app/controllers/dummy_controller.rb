class DummyController < ApplicationController
  skip_filter *_process_action_callbacks.map(&:filter)
  
  def index
    render :nothing => true
  end
end
