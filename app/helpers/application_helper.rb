module ApplicationHelper

  def get_follow_link(name, path, options = {})
    link_to(("<span>"+name+"</span>").html_safe, path, options)
  end
end
