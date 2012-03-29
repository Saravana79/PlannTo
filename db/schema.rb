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

ActiveRecord::Schema.define(:version => 20120327174641) do

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
  end

  create_table "article_contents", :force => true do |t|
    t.string  "url"
    t.string  "thumbnail"
    t.integer "article_category_id"
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
  end

  add_index "attribute_values", ["item_id"], :name => "ItemIdBasedKey"

  create_table "attributes", :force => true do |t|
    t.string   "name",            :limit => 500, :null => false
    t.string   "attribute_type",  :limit => 100, :null => false
    t.string   "unit_of_measure", :limit => 100
    t.string   "category_name",   :limit => 50
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
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
    t.string   "uuid",        :limit => 36
    t.integer  "user_id"
    t.integer  "itemtype_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "buying_plans", ["uuid"], :name => "index_buying_plans_on_uuid"

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

  create_table "content_item_relations", :force => true do |t|
    t.integer  "content_id", :null => false
    t.integer  "item_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "itemtype"
  end

  create_table "contents", :force => true do |t|
    t.string   "title",       :limit => 200
    t.text     "description"
    t.string   "type",                       :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "itemtype_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip_address"
  end

  create_table "debates", :force => true do |t|
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

  create_table "facebooks", :force => true do |t|
    t.string   "identifier"
    t.string   "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "field_values", :force => true do |t|
    t.integer  "field_id"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fields", :force => true do |t|
    t.integer  "itemtype_id"
    t.string   "name"
    t.string   "field_type"
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

  create_table "image_contents", :force => true do |t|
    t.string   "image_content_file_name"
    t.string   "image_content_content_type"
    t.integer  "image_content_file_size"
    t.datetime "image_content_updated_at"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "sender_id",                   :null => false
    t.integer  "item_id"
    t.integer  "item_type"
    t.string   "email",                       :null => false
    t.integer  "follow_type",                 :null => false
    t.string   "message",     :limit => 2000
    t.string   "token",                       :null => false
    t.string   "user_ip",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_attribute_tag_relations", :force => true do |t|
    t.integer  "attribute_id",                 :null => false
    t.integer  "item_id",                      :null => false
    t.string   "value",        :limit => 5000, :null => false
    t.integer  "itemtype_id",                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "itemdetails", :force => true do |t|
    t.integer  "shippingunit"
    t.integer  "guarantee"
    t.integer  "guaranteeunit"
    t.boolean  "iscashondeliveryavailable"
    t.integer  "saveonpercentage"
    t.integer  "savepercentage"
    t.integer  "cashback"
    t.boolean  "isemiavailable"
    t.string   "site"
    t.string   "shipping"
    t.integer  "item_details_id"
    t.integer  "itemid"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "itemexternalurls", :primary_key => "ID", :force => true do |t|
    t.integer "ItemID",                    :null => false
    t.text    "URL",                       :null => false
    t.string  "URLSource", :limit => 2000, :null => false
  end

  create_table "itemimages", :primary_key => "ID", :force => true do |t|
    t.integer "ItemId",                    :null => false
    t.string  "ImageURL",  :limit => 4000, :null => false
    t.boolean "IsDefault",                 :null => false
  end

  create_table "itemrelationships", :force => true do |t|
    t.integer  "item_id",        :null => false
    t.integer  "relateditem_id", :null => false
    t.string   "relationtype",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", :force => true do |t|
    t.string   "name",               :limit => 2000,                    :null => false
    t.text     "description",                                           :null => false
    t.string   "imageurl",           :limit => 2000
    t.integer  "itemtype_id"
    t.integer  "group_id"
    t.boolean  "editablebynonadmin",                 :default => false, :null => false
    t.boolean  "needapproval",                       :default => false, :null => false
    t.boolean  "isgroupheader",                      :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
  end

  create_table "itemtypes", :force => true do |t|
    t.string   "itemtype",    :limit => 2000, :null => false
    t.string   "description", :limit => 5000, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "creator_ip"
    t.string   "updater_ip"
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

  create_table "points", :force => true do |t|
    t.integer  "user_id"
    t.integer  "object_id"
    t.string   "object_type"
    t.string   "reason"
    t.integer  "points"
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

  create_table "question_contents", :force => true do |t|
    t.string  "format",      :limit => 1
    t.boolean "is_answered",              :default => false
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

  create_table "review_contents", :force => true do |t|
    t.integer "rating"
    t.boolean "recommend_this"
    t.string  "pros"
    t.string  "cons"
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

  create_table "tips", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.integer  "item_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_answers", :force => true do |t|
    t.text     "answer"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
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
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "reputation",                            :default => 0,  :null => false
    t.integer  "invitation_id"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "vendors", :force => true do |t|
    t.string   "name"
    t.string   "baseurl"
    t.string   "imageurl"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

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

  create_view "view_answer_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`answer_contents`.`question_content_id` AS `question_content_id`,`answer_contents`.`format` AS `format`,`answer_contents`.`mark_as_answer` AS `mark_as_answer` from (`contents` join `answer_contents`) where (`contents`.`id` = `answer_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :question_content_id
    v.column :format
    v.column :mark_as_answer
  end

  create_view "view_article_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`article_contents`.`url` AS `url`,`article_contents`.`thumbnail` AS `thumbnail`,`article_contents`.`article_category_id` AS `article_category_id` from (`contents` join `article_contents`) where (`contents`.`id` = `article_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :url
    v.column :thumbnail
    v.column :article_category_id
  end

  create_view "view_image_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`image_contents`.`image_content_file_name` AS `image_content_file_name`,`image_contents`.`image_content_content_type` AS `image_content_content_type`,`image_contents`.`image_content_file_size` AS `image_content_file_size`,`image_contents`.`image_content_updated_at` AS `image_content_updated_at` from (`contents` join `image_contents`) where (`contents`.`id` = `image_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :image_content_file_name
    v.column :image_content_content_type
    v.column :image_content_file_size
    v.column :image_content_updated_at
  end

  create_view "view_question_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`question_contents`.`format` AS `format`,`question_contents`.`is_answered` AS `is_answered` from (`contents` join `question_contents`) where (`contents`.`id` = `question_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :format
    v.column :is_answered
  end

  create_view "view_rankings", "select `points`.`user_id` AS `user_id`,sum(`points`.`points`) AS `points` from `points` group by `points`.`user_id` order by sum(`points`.`points`)", :force => true do |v|
    v.column :user_id
    v.column :points
  end

  create_view "view_review_contents", "select `contents`.`id` AS `id`,`contents`.`title` AS `title`,`contents`.`description` AS `description`,`contents`.`type` AS `type`,`contents`.`created_by` AS `created_by`,`contents`.`updated_by` AS `updated_by`,`contents`.`itemtype_id` AS `itemtype_id`,`contents`.`created_at` AS `created_at`,`contents`.`updated_at` AS `updated_at`,`review_contents`.`rating` AS `rating`,`review_contents`.`recommend_this` AS `recommend_this`,`review_contents`.`pros` AS `pros`,`review_contents`.`cons` AS `cons` from (`contents` join `review_contents`) where (`contents`.`id` = `review_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :rating
    v.column :recommend_this
    v.column :pros
    v.column :cons
  end

  create_view "view_top_contributors", "select `p`.`user_id` AS `user_id`,`r`.`item_id` AS `item_id`,sum(`p`.`points`) AS `points` from (`points` `p` join `content_item_relations` `r` on((`p`.`object_id` = `r`.`content_id`))) where (`p`.`object_type` = 'Content') group by `r`.`item_id`,`p`.`user_id` order by sum(`p`.`points`)", :force => true do |v|
    v.column :user_id
    v.column :item_id
    v.column :points
  end

  create_view "view_video_contents", "select `view_article_contents`.`id` AS `id`,`view_article_contents`.`title` AS `title`,`view_article_contents`.`description` AS `description`,`view_article_contents`.`type` AS `type`,`view_article_contents`.`created_by` AS `created_by`,`view_article_contents`.`updated_by` AS `updated_by`,`view_article_contents`.`itemtype_id` AS `itemtype_id`,`view_article_contents`.`created_at` AS `created_at`,`view_article_contents`.`updated_at` AS `updated_at`,`view_article_contents`.`url` AS `url`,`view_article_contents`.`thumbnail` AS `thumbnail`,`view_article_contents`.`article_category_id` AS `article_category_id`,`video_contents`.`youtube` AS `youtube` from (`view_article_contents` join `video_contents`) where (`view_article_contents`.`id` = `video_contents`.`id`)", :force => true do |v|
    v.column :id
    v.column :title
    v.column :description
    v.column :type
    v.column :created_by
    v.column :updated_by
    v.column :itemtype_id
    v.column :created_at
    v.column :updated_at
    v.column :url
    v.column :thumbnail
    v.column :article_category_id
    v.column :youtube
  end

end
