class CreateImpressionAndClick
  @queue = :create_impression_and_click

  def self.perform(class_name, obj_params)
    p 8888888888888888888888888
    p Time.now
    if class_name == "AddImpression"
      AddImpression.create_new_record(obj_params)
    elsif class_name == "Click"
      Click.create_new_record(obj_params)
    end
  end
end
