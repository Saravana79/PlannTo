# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140722134240) do

  create_table "add_impressions", :force => true do |t|
    t.string   "advertisement_type"
    t.integer  "advertisement_id"
    t.integer  "impression_id"
    t.string   "item_id",            :limit => 100
    t.string   "hosted_site_url"
    t.datetime "impression_time"
    t.integer  "publisher_id"
    t.integer  "user_id"
    t.string   "ip_address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "itemsaccess"
    t.string   "params"
    t.string   "temp_user_id"
    t.string   "sid",                :limit => 100
    t.float    "winning_price"
  end

  add_index "add_impressions", ["advertisement_id"], :name => "index_add_impressions_on_advertisement_id"
  add_index "add_impressions", ["advertisement_type"], :name => "index_add_impressions_on_advertisement_type"
  add_index "add_impressions", ["impression_id"], :name => "index_add_impressions_on_impression_id"
  add_index "add_impressions", ["impression_time"], :name => "index_add_impressions_on_impression_time"
  add_index "add_impressions", ["item_id"], :name => "index_add_impressions_on_item_id"
  add_index "add_impressions", ["publisher_id"], :name => "publihserid"
  add_index "add_impressions", ["user_id"], :name => "index_add_impressions_on_user_id"

  create_table "advertisements", :force => true do |t|
    t.string   "name"
    t.string   "budget"
    t.string   "bid"
    t.float    "cost"
    t.string   "advertisement_type"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "content_id"
    t.integer  "status",                                            :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "click_url"
    t.integer  "user_id"
    t.integer  "vendor_id"
    t.decimal  "ecpm",               :precision => 10, :scale => 0
    t.decimal  "ectr",               :precision => 10, :scale => 0
    t.string   "template_type"
    t.string   "offer"
    t.string   "offer_url"
    t.date     "expiry_date"
  end

  create_table "aggregated_details", :force => true do |t|
    t.string   "entity_type"
    t.integer  "entity_id"
    t.integer  "impressions_count", :default => 0
    t.integer  "clicks_count",      :default => 0
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "answer_contents", :force => true do |t|
    t.integer "question_content_id"
    t.string  "format",              :limit => 1
    t.boolean "mark_as_answer",                   :default => false
  end

  create_table "answers", :force => true do |t|
    t.integer  "question_id"
    t.text     "content"
    t.string   "format",         :limit => 1
    t.boolean  "mark_as_answer",              :default => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updator_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "article_categories", :force => true do |t|
    t.string   "name",                       :null => false
    t.integer  "itemtype_id", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "orderby"
  end

  add_index "article_categories", ["itemtype_id"], :name => "ItemtypeID"

  create_table "article_contents", :force => true do |t|
    t.string  "url"
    t.string  "thumbnail"
    t.string  "field1"
    t.string  "field2",    :limit => 800
    t.string  "field3",    :limit => 800
    t.string  "field4",    :limit => 1000
    t.boolean "video"
    t.string  "domain"
  end

  add_index "article_contents", ["url"], :name => "url"

  create_table "attribute_comparison_lists", :force => true do |t|
    t.string   "title"
    t.integer  "attribute_id"
    t.integer  "itemtype_id"
    t.string   "value"
    t.string   "condition"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_order"
  end

  create_table "attribute_values", :force => true do |t|
    t.integer  "attribute_id",                                       :null => false
    t.integer  "item_id",                                            :null => false
    t.string   "value",            :limit => 5000,                   :null => false
    t.string   "addition_comment", :limit => 5000
    t.boolean  "is_visible",                       :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
    t.string   "hyperlink",        :limit => 1000
  end

  add_index "attribute_values", ["item_id"], :name => "ItemIdBasedKey"

  create_table "attributes", :force => true do |t|
    t.string   "name",            :limit => 500,  :null => false
    t.string   "attribute_type",  :limit => 100,  :null => false
    t.string   "unit_of_measure", :limit => 100
    t.string   "category_name",   :limit => 50
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
    t.string   "description",     :limit => 1000
    t.string   "hyperlink",       :limit => 1000
    t.integer  "sortorder"
  end

  create_table "attributes_relationships", :force => true do |t|
    t.integer  "attribute_id"
    t.integer  "itemtype_id"
    t.integer  "Priority"
    t.boolean  "is_filterable"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "attributesrelationships", :force => true do |t|
    t.integer "attribute_id", :null => false
    t.integer "itemtype_id",  :null => false
    t.integer "Priority",     :null => false
  end

  create_table "avatars", :force => true do |t|
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "best_uses", :force => true do |t|
    t.string   "title",      :limit => 50, :null => false
    t.integer  "item_id",                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
  end

  create_table "browser_preferences", :force => true do |t|
    t.integer  "user_id"
    t.integer  "search_display_attribute_id"
    t.string   "value_1"
    t.string   "value_2"
    t.integer  "itemtype_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip"
  end

  create_table "buying_plans", :force => true do |t|
    t.string   "uuid",                     :limit => 36
    t.integer  "user_id"
    t.integer  "itemtype_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted"
    t.string   "items_considered"
    t.boolean  "completed",                              :default => false
    t.integer  "owned_item_id"
    t.text     "owned_item_description"
    t.string   "temporary_buying_plan_ip"
  end

  add_index "buying_plans", ["uuid"], :name => "index_buying_plans_on_uuid"

  create_table "clicks", :force => true do |t|
    t.uuid     "impression_id"
    t.string   "click_url"
    t.string   "hosted_site_url"
    t.datetime "timestamp"
    t.integer  "item_id"
    t.integer  "user_id"
    t.string   "ipaddress"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publisher_id"
    t.integer  "vendor_id"
    t.string   "source_type"
    t.string   "temp_user_id"
    t.integer  "old_impression_id"
    t.integer  "advertisement_id"
    t.string   "sid"
  end

  add_index "clicks", ["advertisement_id"], :name => "index_clicks_on_advertisement_id"

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.string   "role",                           :default => "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
    t.integer  "status"
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "cons", :force => true do |t|
    t.string   "title",      :limit => 50, :null => false
    t.integer  "item_id",                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
  end

  create_table "content_actions", :force => true do |t|
    t.integer  "action_done_by"
    t.string   "action"
    t.text     "reason"
    t.integer  "content_id"
    t.datetime "time"
    t.boolean  "sent_mail",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_ad_details", :force => true do |t|
    t.string   "url"
    t.integer  "impressions"
    t.integer  "clicks"
    t.float    "ectr"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "orders"
  end

  create_table "content_as_items", :force => true do |t|
    t.integer  "content_id"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_item_relations", :force => true do |t|
    t.integer  "content_id", :null => false
    t.integer  "item_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "itemtype"
  end

  add_index "content_item_relations", ["content_id"], :name => "Item_content_id"
  add_index "content_item_relations", ["item_id"], :name => "Item_Id"

  create_table "content_itemtype_relations", :force => true do |t|
    t.integer  "itemtype_id"
    t.integer  "content_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_itemtype_relations", ["content_id"], :name => "content_id"

  create_table "content_photos", :force => true do |t|
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "content_id"
    t.string   "url"
  end

  add_index "content_photos", ["content_id"], :name => "ContentIdBased"

  create_table "contents", :force => true do |t|
    t.string   "title",                  :limit => 200
    t.text     "description"
    t.string   "type",                                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "itemtype_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip_address"
    t.string   "sub_type"
    t.boolean  "deleted"
    t.string   "slug"
    t.integer  "no_of_votes"
    t.integer  "positive_votes"
    t.integer  "negative_votes"
    t.integer  "total_votes"
    t.integer  "comments_count"
    t.integer  "status"
    t.string   "content_guide_info_ids"
  end

  add_index "contents", ["created_by"], :name => "createdby"
  add_index "contents", ["itemtype_id"], :name => "Itemtype_id"
  add_index "contents", ["slug"], :name => "index_contents_on_slug"

  create_table "contents_guides", :force => true do |t|
    t.integer  "content_id"
    t.integer  "guide_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contents_guides", ["content_id", "guide_id"], :name => "Content_id"

  create_table "dealer_locators", :force => true do |t|
    t.integer  "item_id"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "debates", :force => true do |t|
    t.integer  "item_id",       :null => false
    t.integer  "review_id",     :null => false
    t.integer  "argument_id",   :null => false
    t.string   "argument_type", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
  end

  create_table "error_messages", :force => true do |t|
    t.text     "class_name"
    t.text     "message"
    t.text     "trace"
    t.text     "params"
    t.text     "target_url"
    t.text     "referer_url"
    t.text     "user_agent"
    t.string   "user_info"
    t.string   "app_name"
    t.string   "doc_root"
    t.string   "ip_address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facebook_counts", :force => true do |t|
    t.integer  "content_id"
    t.integer  "share_count"
    t.integer  "like_count"
    t.integer  "comment_count"
    t.integer  "total_count"
    t.integer  "click_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "facebook_counts", ["content_id"], :name => "Contentid"

  create_table "facebooks", :force => true do |t|
    t.string   "identifier"
    t.string   "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feed_urls", :force => true do |t|
    t.integer  "feed_id"
    t.string   "url"
    t.string   "title"
    t.integer  "status"
    t.string   "source"
    t.string   "category"
    t.text     "summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.string   "images",        :default => ""
    t.integer  "priorities",    :default => 3
    t.integer  "missing_count", :default => 0
  end

  create_table "feeds", :force => true do |t|
    t.string   "url"
    t.string   "title"
    t.string   "category"
    t.datetime "last_updated_at"
    t.integer  "created_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "process_type"
    t.string   "process_value"
    t.integer  "priorities",      :default => 3
  end

  create_table "field_values", :force => true do |t|
    t.integer  "field_id"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "item_id"
  end

  create_table "fields", :force => true do |t|
    t.integer  "itemtype_id"
    t.string   "name"
    t.string   "field_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flags", :force => true do |t|
    t.integer  "content_id"
    t.integer  "flagged_by"
    t.string   "type"
    t.text     "reason"
    t.boolean  "verfied"
    t.integer  "verified_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "follows", :force => true do |t|
    t.integer  "followable_id",                      :null => false
    t.string   "followable_type",                    :null => false
    t.integer  "follower_id",                        :null => false
    t.string   "follower_type",                      :null => false
    t.boolean  "blocked",         :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "follow_type"
  end

  add_index "follows", ["followable_id", "followable_type"], :name => "fk_followables"
  add_index "follows", ["follower_id", "follower_type"], :name => "fk_follows"

  create_table "guides", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "history_details", :force => true do |t|
    t.integer  "user_id"
    t.string   "site_url"
    t.string   "ip_address"
    t.string   "plannto_location"
    t.datetime "redirection_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hotel_vendor_details", :force => true do |t|
    t.integer  "item_id"
    t.string   "vendor_id"
    t.integer  "reference_id"
    t.float    "price"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "image_contents", :force => true do |t|
    t.string   "image_content_file_name"
    t.string   "image_content_content_type"
    t.integer  "image_content_file_size"
    t.datetime "image_content_updated_at"
  end

  create_table "images", :force => true do |t|
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "imageable_id"
    t.string   "imageable_type"
    t.string   "ad_size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "impression_missings", :force => true do |t|
    t.integer  "count",           :default => 0
    t.string   "req_type",        :default => "PriceComparison"
    t.datetime "created_time",    :default => '2013-11-14 17:19:30'
    t.datetime "updated_time",    :default => '2013-11-14 17:19:30'
    t.string   "hosted_site_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vendor_id"
    t.integer  "status"
  end

  create_table "impressions", :force => true do |t|
    t.string   "impressionable_type"
    t.integer  "impressionable_id"
    t.integer  "user_id"
    t.string   "ip_address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "sender_id",                   :null => false
    t.integer  "item_id"
    t.string   "item_type"
    t.string   "email",                       :null => false
    t.string   "follow_type",                 :null => false
    t.string   "message",     :limit => 2000
    t.string   "token",                       :null => false
    t.string   "user_ip",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_ad_details", :force => true do |t|
    t.integer  "item_id"
    t.integer  "impressions"
    t.integer  "clicks"
    t.float    "ectr"
    t.string   "related_item_ids"
    t.integer  "new_version_id"
    t.integer  "old_version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "orders"
  end

  create_table "item_attribute_tag_relations", :force => true do |t|
    t.integer  "attribute_id",                 :null => false
    t.integer  "item_id",                      :null => false
    t.string   "value",        :limit => 5000
    t.integer  "itemtype_id",                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_contents_relations_cache", :force => true do |t|
    t.integer  "item_id"
    t.integer  "content_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_contents_relations_cache", ["item_id", "content_id"], :name => "itemid"

  create_table "item_pro_cons", :force => true do |t|
    t.integer  "pro_con_category_id"
    t.string   "proorcon"
    t.integer  "item_id"
    t.integer  "article_content_id"
    t.string   "text"
    t.integer  "index"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "letters_count"
    t.integer  "words_count"
  end

  create_table "item_ratings", :force => true do |t|
    t.decimal  "expert_review_avg_rating",  :precision => 8,  :scale => 2
    t.integer  "expert_review_count"
    t.integer  "expert_review_total_count"
    t.decimal  "user_review_avg_rating",    :precision => 8,  :scale => 2
    t.integer  "user_review_count"
    t.integer  "user_review_total_count"
    t.decimal  "average_rating",            :precision => 8,  :scale => 2
    t.integer  "review_count"
    t.integer  "review_total_count"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "final_rating",              :precision => 10, :scale => 2
    t.integer  "rank"
  end

  create_table "item_specification_summary_lists", :force => true do |t|
    t.integer  "attribute_id"
    t.integer  "itemtype_id"
    t.string   "condition"
    t.string   "value1"
    t.string   "value2"
    t.string   "title"
    t.string   "description"
    t.string   "proorcon"
    t.integer  "sortorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "itemdetails", :primary_key => "item_details_id", :force => true do |t|
    t.integer  "itemid",                                                                   :null => false
    t.text     "ItemName"
    t.string   "url",                       :limit => 1000
    t.decimal  "price",                                     :precision => 16, :scale => 2, :null => false
    t.integer  "status",                                                                   :null => false
    t.string   "shipping",                  :limit => 10
    t.integer  "shippingunit"
    t.decimal  "guarantee",                                 :precision => 16, :scale => 2
    t.integer  "guaranteeunit"
    t.boolean  "iscashondeliveryavailable",                                                :null => false
    t.decimal  "savepercentage",                            :precision => 4,  :scale => 0
    t.decimal  "cashback",                                  :precision => 16, :scale => 2
    t.boolean  "isemiavailable",                                                           :null => false
    t.string   "site",                      :limit => 45
    t.datetime "last_updated"
    t.datetime "last_verified_date"
    t.boolean  "IsError"
    t.string   "errordetails",              :limit => 200
    t.string   "offer",                     :limit => 1000
    t.integer  "itemexternalurl_id"
    t.string   "Image"
    t.decimal  "mrpprice",                                  :precision => 10, :scale => 0
  end

  add_index "itemdetails", ["itemexternalurl_id"], :name => "itemexternalurl_ids"
  add_index "itemdetails", ["itemid"], :name => "itemdetails_items"

  create_table "itemdetails_archive", :primary_key => "item_details_id", :force => true do |t|
    t.integer  "itemid",                                                                 :null => false
    t.decimal  "price",                                   :precision => 16, :scale => 2, :null => false
    t.integer  "status",                                                                 :null => false
    t.string   "shipping",                  :limit => 10
    t.integer  "shippingunit"
    t.decimal  "guarantee",                               :precision => 16, :scale => 2
    t.integer  "guaranteeunit"
    t.boolean  "iscashondeliveryavailable",                                              :null => false
    t.decimal  "savepercentage",                          :precision => 4,  :scale => 0
    t.decimal  "cashback",                                :precision => 16, :scale => 2
    t.boolean  "isemiavailable",                                                         :null => false
    t.string   "site",                      :limit => 45
    t.datetime "last_updated"
    t.datetime "price_startDate"
    t.datetime "price_endDate"
  end

  add_index "itemdetails_archive", ["itemid"], :name => "itemdetails_items"

  create_table "itemexternalurls", :primary_key => "ID", :force => true do |t|
    t.integer  "ItemID",                                          :null => false
    t.text     "URL",                                             :null => false
    t.string   "URLSource",    :limit => 2000,                    :null => false
    t.boolean  "is_verified",                  :default => false
    t.integer  "itemtype_id"
    t.datetime "last_updated"
    t.integer  "status",                       :default => 0
  end

  add_index "itemexternalurls", ["URL"], :name => "url", :length => {"URL"=>255}
  add_index "itemexternalurls", ["itemtype_id"], :name => "fk_itemexternalurls_itemtypes_typeid"

  create_table "itemimages", :primary_key => "ID", :force => true do |t|
    t.integer "ItemId",                    :null => false
    t.string  "ImageURL",  :limit => 4000, :null => false
    t.boolean "IsDefault",                 :null => false
  end

  add_index "itemimages", ["ItemId"], :name => "ItemID"

  create_table "itemrelationships", :force => true do |t|
    t.integer  "item_id",        :null => false
    t.integer  "relateditem_id", :null => false
    t.string   "relationtype",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "itemrelationships", ["item_id"], :name => "itemid"
  add_index "itemrelationships", ["relateditem_id"], :name => "relateditemid"

  create_table "items", :force => true do |t|
    t.string   "name",                    :limit => 2000,                    :null => false
    t.text     "description",                                                :null => false
    t.string   "imageurl",                :limit => 2000
    t.integer  "itemtype_id"
    t.integer  "group_id"
    t.boolean  "editablebynonadmin",                      :default => false, :null => false
    t.boolean  "needapproval",                            :default => false, :null => false
    t.boolean  "isgroupheader",                           :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
    t.string   "status"
    t.string   "slug"
    t.integer  "new_version_item_id"
    t.string   "alternative_name"
    t.string   "hidden_alternative_name"
  end

  add_index "items", ["itemtype_id"], :name => "ItemType"
  add_index "items", ["slug"], :name => "index_items_on_slug"

  create_table "itemtypes", :force => true do |t|
    t.string   "itemtype",    :limit => 2000, :null => false
    t.string   "description", :limit => 5000, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
    t.integer  "orderby"
  end

  create_table "messages", :force => true do |t|
    t.string   "topic"
    t.text     "body"
    t.integer  "received_messageable_id"
    t.string   "received_messageable_type"
    t.integer  "sent_messageable_id"
    t.string   "sent_messageable_type"
    t.boolean  "opened",                     :default => false
    t.boolean  "recipient_delete",           :default => false
    t.boolean  "sender_delete",              :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ancestry"
    t.boolean  "recipient_permanent_delete", :default => false
    t.boolean  "sender_permanent_delete",    :default => false
  end

  add_index "messages", ["ancestry"], :name => "index_messages_on_ancestry"
  add_index "messages", ["sent_messageable_id", "received_messageable_id"], :name => "acts_as_messageable_ids"

  create_table "missing_ad_details", :force => true do |t|
    t.string   "url"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_histories", :force => true do |t|
    t.datetime "order_date"
    t.integer  "no_of_orders"
    t.float    "total_revenue"
    t.integer  "publisher_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vendor_ids"
    t.string   "order_status"
    t.string   "payment_status"
    t.integer  "item_id"
    t.string   "item_name"
    t.string   "product_price"
    t.uuid     "impression_id"
    t.integer  "old_impression_id"
    t.datetime "payment_date"
    t.integer  "payment_report_id"
    t.string   "sid"
  end

  create_table "payment_reports", :force => true do |t|
    t.integer  "publisher_id"
    t.datetime "payment_date"
    t.float    "commission_amount"
    t.float    "tax_amount"
    t.float    "final_amount"
    t.string   "payment_method"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "plannto_percentage"
    t.float    "plannto_amount"
  end

  create_table "points", :force => true do |t|
    t.integer  "user_id"
    t.integer  "object_id"
    t.string   "object_type"
    t.string   "reason"
    t.float    "points"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", :force => true do |t|
    t.integer  "buying_plan_id"
    t.integer  "search_display_attribute_id"
    t.string   "value_1"
    t.string   "value_2"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pro_con_categories", :force => true do |t|
    t.integer  "itemtype_id"
    t.string   "category"
    t.string   "list"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_order"
  end

  create_table "proposals", :force => true do |t|
    t.integer  "item_id"
    t.integer  "buying_plan_id"
    t.date     "expiry_date"
    t.float    "item_price"
    t.string   "delivery_period"
    t.float    "shipping_cost"
    t.string   "color"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "vendor_id"
    t.integer  "comments_count"
  end

  create_table "pros", :force => true do |t|
    t.string   "title",      :limit => 50, :null => false
    t.integer  "item_id",                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
  end

  create_table "publisher_vendors", :force => true do |t|
    t.integer  "publisher_id"
    t.integer  "vendor_id"
    t.string   "affliateid"
    t.string   "trackid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "publishers", :force => true do |t|
    t.string   "publisher_url"
    t.text     "contact_details"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "vendor_ids"
    t.string   "exclude_vendor_ids"
  end

  create_table "question_contents", :force => true do |t|
    t.string  "format",      :limit => 1
    t.boolean "is_answered",              :default => false
    t.string  "thumbnail"
  end

  create_table "questions", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "format",      :limit => 1
    t.boolean  "is_answered",              :default => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updator_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rates", :force => true do |t|
    t.integer "score"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "rate_id"
    t.integer  "rateable_id"
    t.string   "rateable_type", :limit => 32
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ratings", ["rate_id"], :name => "index_ratings_on_rate_id"
  add_index "ratings", ["rateable_id", "rateable_type"], :name => "index_ratings_on_rateable_id_and_rateable_type"

  create_table "recommendations", :force => true do |t|
    t.integer  "user_answer_id"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "related_items", :force => true do |t|
    t.integer  "item_id"
    t.integer  "related_item_id"
    t.integer  "variance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "related_items", ["item_id"], :name => "ItemID"

  create_table "reports", :force => true do |t|
    t.string   "report_type"
    t.text     "description"
    t.string   "reportable_type"
    t.integer  "reportable_id"
    t.integer  "reported_by"
    t.string   "report_from_page"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "review_contents", :force => true do |t|
    t.integer "rating"
    t.boolean "recommend_this"
    t.string  "pros"
    t.string  "cons"
    t.string  "thumbnail"
  end

  create_table "reviews", :force => true do |t|
    t.string   "title",          :limit => 200
    t.string   "description",    :limit => 5000
    t.integer  "rating"
    t.boolean  "recommend_this"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
  end

  create_table "search_display_attributes", :force => true do |t|
    t.string   "attribute_display_name"
    t.integer  "attribute_id"
    t.integer  "itemtype_id"
    t.string   "type"
    t.string   "value_type"
    t.string   "minimum_value"
    t.string   "maximum_value"
    t.string   "actual_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "step"
    t.string   "range"
    t.integer  "sortorder"
  end

  create_table "share_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shares", :force => true do |t|
    t.string   "url"
    t.string   "title"
    t.string   "description"
    t.string   "thumbnail"
    t.string   "youtube"
    t.string   "user_description"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "user_id"
    t.integer  "share_type_id"
    t.string   "ip_address"
  end

  add_index "shares", ["item_id"], :name => "index_shares_on_item_id"

  create_table "sid_ad_details", :force => true do |t|
    t.string   "sid"
    t.integer  "impressions"
    t.integer  "clicks"
    t.float    "ectr"
    t.integer  "orders"
    t.string   "sample_url"
    t.string   "domain"
    t.string   "size"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "avg_winning_price"
  end

  create_table "sourceitems", :force => true do |t|
    t.string   "name",            :limit => 100, :null => false
    t.string   "url",             :limit => 500, :null => false
    t.string   "urlsource",       :limit => 100, :null => false
    t.integer  "status",                         :null => false
    t.integer  "matchfoundby"
    t.integer  "matchitemid"
    t.string   "matchitemname",   :limit => 100
    t.boolean  "verified",                       :null => false
    t.integer  "itemtype_id",                    :null => false
    t.string   "created_by",      :limit => 50,  :null => false
    t.string   "updated_by",      :limit => 50
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at"
    t.integer  "suggestion_id"
    t.string   "suggestion_name"
  end

  add_index "sourceitems", ["matchitemid"], :name => "matchitemid_itemid"
  add_index "sourceitems", ["url"], :name => "url", :length => {"url"=>333}

  create_table "sourceitems1", :force => true do |t|
    t.string   "name",          :limit => 100, :null => false
    t.string   "url",           :limit => 500, :null => false
    t.string   "urlsource",     :limit => 100, :null => false
    t.integer  "status",                       :null => false
    t.integer  "matchfoundby"
    t.integer  "matchitemid"
    t.string   "matchitemname", :limit => 100
    t.boolean  "verified",                     :null => false
    t.integer  "itemtype_id",                  :null => false
    t.string   "created_by",    :limit => 50,  :null => false
    t.string   "updated_by",    :limit => 50
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at"
  end

  add_index "sourceitems1", ["matchitemid"], :name => "matchitemid_itemid"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "temp_article_contents", :force => true do |t|
    t.string "url", :limit => 500
  end

  create_table "tips", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.integer  "item_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topic_itemtype_relations", :force => true do |t|
    t.integer  "item_id"
    t.integer  "itemtype_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_activities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "related_id"
    t.string   "related_activity"
    t.string   "related_activity_type"
    t.datetime "time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "activity_id"
    t.string   "ip_address"
  end

  create_table "user_answers", :force => true do |t|
    t.text     "answer"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "no_of_votes"
    t.integer  "positive_votes"
    t.integer  "negative_votes"
    t.integer  "total_votes"
    t.integer  "comments_count"
  end

  create_table "user_images", :force => true do |t|
    t.string   "uploaded_image_file_name"
    t.string   "uploaded_image_content_type"
    t.integer  "uploaded_image_file_size"
    t.datetime "uploaded_image_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_question_answers", :force => true do |t|
    t.integer  "user_question_id"
    t.integer  "user_answer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_questions", :force => true do |t|
    t.integer  "itemtype_id"
    t.integer  "user_id"
    t.text     "question"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "buying_plan_id"
    t.boolean  "plannto_network"
    t.string   "title"
    t.integer  "no_of_votes"
    t.integer  "positive_votes"
    t.integer  "negative_votes"
    t.integer  "total_votes"
    t.integer  "comments_count"
  end

  create_table "user_relationships", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "relationship_type"
    t.integer  "relationship_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "",    :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "facebook_id"
    t.integer  "reputation",                            :default => 0,     :null => false
    t.integer  "invitation_id"
    t.string   "username"
    t.string   "uid"
    t.string   "token"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.boolean  "is_admin",                              :default => false
    t.string   "description"
    t.boolean  "my_feeds_email",                        :default => true
    t.string   "location"
    t.string   "profile_view_setting",                  :default => "pu"
    t.boolean  "active",                                :default => true
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["uid"], :name => "index_users_on_uid"

  create_table "vendor_details", :force => true do |t|
    t.string  "name",         :limit => 500,  :null => false
    t.string  "baseurl",      :limit => 2000, :null => false
    t.string  "imageurl",     :limit => 2000, :null => false
    t.string  "params"
    t.integer "item_id"
    t.string  "param1"
    t.text    "default_text"
  end

  create_table "video_contents", :force => true do |t|
    t.string "youtube"
  end

  create_table "vote_counts", :force => true do |t|
    t.integer  "voteable_id",         :null => false
    t.string   "voteable_type",       :null => false
    t.integer  "vote_count",          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vote_count_positive"
    t.integer  "vote_count_negative"
    t.integer  "comment_count"
  end

  add_index "vote_counts", ["voteable_id", "voteable_type"], :name => "Votableid"

  create_table "votes", :force => true do |t|
    t.boolean  "vote",          :default => false
    t.integer  "voteable_id",                      :null => false
    t.string   "voteable_type",                    :null => false
    t.integer  "voter_id"
    t.string   "voter_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "votes", ["voteable_id", "voteable_type"], :name => "index_votes_on_voteable_id_and_voteable_type"
  add_index "votes", ["voter_id", "voter_type", "voteable_id", "voteable_type"], :name => "fk_one_vote_per_user_per_entity", :unique => true
  add_index "votes", ["voter_id", "voter_type"], :name => "index_votes_on_voter_id_and_voter_type"

  create_view "view_answer_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`contents`.`ip_address` AS `ip_address`,`contents`.`sub_type` AS `sub_type`,`contents`.`deleted` AS `deleted`,`contents`.`slug` AS `slug`,`contents`.`no_of_votes` AS `no_of_votes`,`contents`.`positive_votes` AS `positive_votes`,`contents`.`negative_votes` AS `negative_votes`,`contents`.`total_votes` AS `total_votes`,`contents`.`comments_count` AS `comments_count`,`contents`.`status` AS `status`,`contents`.`content_guide_info_ids` AS `content_guide_info_ids`,`answer_contents`.`question_content_id` AS `question_content_id`,`answer_contents`.`format` AS `format`,`answer_contents`.`mark_as_answer` AS `mark_as_answer` from (`contents` join `answer_contents`) where (`contents`.`id` = `answer_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :ip_address
    v.column :sub_type
    v.column :deleted
    v.column :slug
    v.column :no_of_votes
    v.column :positive_votes
    v.column :negative_votes
    v.column :total_votes
    v.column :comments_count
    v.column :status
    v.column :content_guide_info_ids
    v.column :question_content_id
    v.column :format
    v.column :mark_as_answer
  end

  create_view "view_article_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`contents`.`ip_address` AS `ip_address`,`contents`.`sub_type` AS `sub_type`,`contents`.`deleted` AS `deleted`,`contents`.`slug` AS `slug`,`contents`.`no_of_votes` AS `no_of_votes`,`contents`.`positive_votes` AS `positive_votes`,`contents`.`negative_votes` AS `negative_votes`,`contents`.`total_votes` AS `total_votes`,`contents`.`comments_count` AS `comments_count`,`contents`.`status` AS `status`,`contents`.`content_guide_info_ids` AS `content_guide_info_ids`,`article_contents`.`url` AS `url`,`article_contents`.`thumbnail` AS `thumbnail`,`article_contents`.`field1` AS `field1`,`article_contents`.`field2` AS `field2`,`article_contents`.`field3` AS `field3`,`article_contents`.`field4` AS `field4`,`article_contents`.`video` AS `video`,`article_contents`.`domain` AS `domain` from (`contents` join `article_contents`) where (`contents`.`id` = `article_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :ip_address
    v.column :sub_type
    v.column :deleted
    v.column :slug
    v.column :no_of_votes
    v.column :positive_votes
    v.column :negative_votes
    v.column :total_votes
    v.column :comments_count
    v.column :status
    v.column :content_guide_info_ids
    v.column :url
    v.column :thumbnail
    v.column :field1
    v.column :field2
    v.column :field3
    v.column :field4
    v.column :video
    v.column :domain
  end

  create_view "view_image_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`contents`.`ip_address` AS `ip_address`,`contents`.`sub_type` AS `sub_type`,`contents`.`deleted` AS `deleted`,`contents`.`slug` AS `slug`,`contents`.`no_of_votes` AS `no_of_votes`,`contents`.`positive_votes` AS `positive_votes`,`contents`.`negative_votes` AS `negative_votes`,`contents`.`total_votes` AS `total_votes`,`contents`.`comments_count` AS `comments_count`,`contents`.`status` AS `status`,`contents`.`content_guide_info_ids` AS `content_guide_info_ids`,`image_contents`.`image_content_file_name` AS `image_content_file_name`,`image_contents`.`image_content_content_type` AS `image_content_content_type`,`image_contents`.`image_content_file_size` AS `image_content_file_size`,`image_contents`.`image_content_updated_at` AS `image_content_updated_at` from (`contents` join `image_contents`) where (`contents`.`id` = `image_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :ip_address
    v.column :sub_type
    v.column :deleted
    v.column :slug
    v.column :no_of_votes
    v.column :positive_votes
    v.column :negative_votes
    v.column :total_votes
    v.column :comments_count
    v.column :status
    v.column :content_guide_info_ids
    v.column :image_content_file_name
    v.column :image_content_content_type
    v.column :image_content_file_size
    v.column :image_content_updated_at
  end

  create_view "view_question_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`contents`.`ip_address` AS `ip_address`,`contents`.`sub_type` AS `sub_type`,`contents`.`deleted` AS `deleted`,`contents`.`slug` AS `slug`,`contents`.`no_of_votes` AS `no_of_votes`,`contents`.`positive_votes` AS `positive_votes`,`contents`.`negative_votes` AS `negative_votes`,`contents`.`total_votes` AS `total_votes`,`contents`.`comments_count` AS `comments_count`,`contents`.`status` AS `status`,`contents`.`content_guide_info_ids` AS `content_guide_info_ids`,`question_contents`.`format` AS `format`,`question_contents`.`is_answered` AS `is_answered`,`question_contents`.`thumbnail` AS `thumbnail` from (`contents` join `question_contents`) where (`contents`.`id` = `question_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :ip_address
    v.column :sub_type
    v.column :deleted
    v.column :slug
    v.column :no_of_votes
    v.column :positive_votes
    v.column :negative_votes
    v.column :total_votes
    v.column :comments_count
    v.column :status
    v.column :content_guide_info_ids
    v.column :format
    v.column :is_answered
    v.column :thumbnail
  end

  create_view "view_rankings", "select `points`.`user_id` AS `user_id`,sum(`points`.`points`) AS `points` from `points` group by `points`.`user_id` order by sum(`points`.`points`)", :force => true do |v|
    v.column :user_id
    v.column :points
  end

  create_view "view_review_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`contents`.`ip_address` AS `ip_address`,`contents`.`sub_type` AS `sub_type`,`contents`.`deleted` AS `deleted`,`contents`.`slug` AS `slug`,`contents`.`no_of_votes` AS `no_of_votes`,`contents`.`positive_votes` AS `positive_votes`,`contents`.`negative_votes` AS `negative_votes`,`contents`.`total_votes` AS `total_votes`,`contents`.`comments_count` AS `comments_count`,`contents`.`status` AS `status`,`contents`.`content_guide_info_ids` AS `content_guide_info_ids`,`review_contents`.`rating` AS `rating`,`review_contents`.`recommend_this` AS `recommend_this`,`review_contents`.`pros` AS `pros`,`review_contents`.`cons` AS `cons`,`review_contents`.`thumbnail` AS `thumbnail` from (`contents` join `review_contents`) where (`contents`.`id` = `review_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :ip_address
    v.column :sub_type
    v.column :deleted
    v.column :slug
    v.column :no_of_votes
    v.column :positive_votes
    v.column :negative_votes
    v.column :total_votes
    v.column :comments_count
    v.column :status
    v.column :content_guide_info_ids
    v.column :rating
    v.column :recommend_this
    v.column :pros
    v.column :cons
    v.column :thumbnail
  end

  create_view "view_top_contributors", "select `p`.`user_id` AS `user_id`,`r`.`item_id` AS `item_id`,sum(`p`.`points`) AS `points` from (`points` `p` join `content_item_relations` `r` on((`p`.`object_id` = `r`.`content_id`))) where (`p`.`object_type` = 'Content') group by `r`.`item_id`,`p`.`user_id` order by sum(`p`.`points`)", :force => true do |v|
    v.column :user_id
    v.column :item_id
    v.column :points
  end

end
