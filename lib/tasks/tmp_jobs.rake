desc "temporary rake task"
task :buying_list_from_user_access => :environment do
  user_access_details = UserAccessDetail.all
  count = user_access_details.count

  loop_count = 0

  user_access_details.each do |user_access_detail|
    loop_count+=1
    article_content = ArticleContent.where(:url => user_access_detail.ref_url).last

    unless article_content.blank?
      user_id = user_access_detail.plannto_user_id
      type = article_content.sub_type
      item_ids = article_content.item_ids.join(",") rescue ""
      itemtype_id = article_content.itemtype_id
      begin
        UserAccessDetail.update_buying_list(user_id, user_access_detail.ref_url, type, item_ids, nil, nil, itemtype_id)
      rescue Exception => e
        p "There was a problem => #{e}"
      end
    end
    p "Remaining #{count-loop_count}"
  end
end