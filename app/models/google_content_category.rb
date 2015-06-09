class GoogleContentCategory < ActiveRecord::Base

  def parent
    GoogleContentCategory.where(:category_id => self.parent_id).last
  end
end
