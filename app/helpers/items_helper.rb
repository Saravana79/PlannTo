module ItemsHelper

  def display_specifications(item)
    specifications = item.priority_specification.collect{|item_attribute| "#{item_attribute.unit_of_measure} #{item_attribute.value} (  #{item_attribute.name}  )"}

    return specifications.to_sentence
  end
end
