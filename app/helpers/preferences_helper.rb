module PreferencesHelper

  def display_empty_row(size)
    if size == 0
      return "<div id='box_-1'></div>"
    else
      return ""
    end
  end

  def can_update_preference?(buying_plan)
    return false if !user_signed_in?
    return current_user == buying_plan.user
  end

  def can_add_recommendation?(buying_plan)
    return false if !user_signed_in?
    return current_user != buying_plan.user
  end

end
