class ChangeDateFormatArticle < ActiveRecord::Migration
  def up
    ArticleContent.where('sub_type in (?)',["Event","Deals"]).each do |art|
       if !art.field1.blank? && (art.sub_type == "Deals" || art.sub_type == "Events")
        date1 = art.field1.split("/")
        date_temp1 = date1[0]
        date1[0] = date1[1]
        date1[1] = date_temp1
        date = date1.join("/")
        art.update_attribute('field1',date)
      end 
      if !art.field2.blank? && (art.sub_type == "Events")
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
