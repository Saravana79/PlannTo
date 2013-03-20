class ChangeDateFormatArticle < ActiveRecord::Migration

  def up
    ArticleContent.where('sub_type in (?)',["Event"]).each do |art|
      if !art.field2.blank? && !art.field2.nil? && (art.sub_type == "Event")
        date2 = art.field2.split("/")
        date_temp2 = date2[0]
        date2[0] = date2[1]
        date2[1] = date_temp2
        date = date2.join("/")
        art.update_attribute('field2',date)
      end
    end
  end

  def down
  end
end
