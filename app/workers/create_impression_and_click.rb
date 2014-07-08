require 'new_relic/agent/method_tracer'
class CreateImpressionAndClick
  @queue = :create_impression_and_click

  def self.perform(class_name, obj_params)
    obj_params = JSON.parse(obj_params)
    class_name.constantize.send("create_new_record", obj_params)
  end

  class << self
    include ::NewRelic::Agent::MethodTracer

    add_method_tracer :generate_image, 'Custom/perform'
  end
end
