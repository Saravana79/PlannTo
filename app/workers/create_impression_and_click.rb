class CreateImpressionAndClick
  extend HerokuResqueAutoScale
  @queue = :create_impression_and_click

  def self.perform(class_name, obj_params)
    if class_name == "AddImpression"
      AddImpression.create_new_record(obj_params)
    elsif class_name == "Click"
      Click.create_new_record(obj_params)
    elsif class_name == "VideoImpression"
      VideoImpression.create_new_record(obj_params)
    end
  end
end
