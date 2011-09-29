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

ActiveRecord::Schema.define(:version => 20110924174032) do

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

  create_table "itemrelationships", :force => true do |t|
    t.integer  "item_id",        :null => false
    t.integer  "relateditem_id", :null => false
    t.string   "relationtype",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", :force => true do |t|
    t.string   "name",               :limit => 2000, :null => false
    t.text     "description",                        :null => false
    t.string   "imageurl",           :limit => 2000
    t.integer  "itemtype_id"
    t.integer  "group_id"
    t.boolean  "editablebynonadmin",                 :null => false
    t.boolean  "needapproval",                       :null => false
    t.boolean  "isgroupheader",                      :null => false
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
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
