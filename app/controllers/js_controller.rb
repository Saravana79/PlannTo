class JsController < ApplicationController

  caches_action :plannto_elec_widget_1_js, :cache_path => proc {|c|  "plannto_elec_widget_1_js"}, :expires_in => 2.hours
  skip_before_filter :cache_follow_items, :store_session_url

  def plannto_elec_widget_1_js

  end
end