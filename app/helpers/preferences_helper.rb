module PreferencesHelper

  def display_empty_row(size)
    if size == 0
      return "<div id='box_-1'></div>"
    else
      return ""
    end
  end

end
