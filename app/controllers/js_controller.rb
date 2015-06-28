class JsController < ApplicationController

  caches_action :plannto_elec_widget_1_js, :cache_path => proc {|c|  "plannto_elec_widget_1_js"}, :expires_in => 2.hours

  def plannto_elec_widget_1_js

  end
end