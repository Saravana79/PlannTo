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

ActiveRecord::Schema.define(:version => 20111221184754) do

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

  create_table "preferences", :force => true do |t|
    t.integer  "user_id"
    t.integer  "search_display_attribute_id"
    t.string   "value_1"
    t.string   "value_2"
    t.integer  "itemtype_id"
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
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "vote_counts", :force => true do |t|
    t.integer  "voteable_id",   :null => false
    t.string   "voteable_type", :null => false
    t.integer  "vote_count",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
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

end
