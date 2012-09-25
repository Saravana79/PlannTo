class User < ActiveRecord::Base
  require 'open-uri'
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :omniauthable, :registerable, :recoverable, :rememberable, 
         :trackable, :validatable
  cache_records :store => :local, :key => "users",:request_cache => true
  REDIS_USER_DETAIL_KEY_PREFIX = "user_details_"
  CACHE_USER_ITEM_HASH = {Follow::ProductFollowType::Owner => "owned_item_ids" ,
    Follow::ProductFollowType::Follow => "follow_item_ids",
    Follow::ProductFollowType::Buyer => "buyer_item_ids"}
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :name, :remember_me, :facebook_id, :invitation_id, :invitation_token, 
                :avatar, :username, :uid, :token,:description
  attr_accessor :follow_type
  acts_as_followable
  acts_as_follower
  acts_as_voter

  # Message configurations
  acts_as_messageable :table_name => "messages",                        # default 'messages'
  :required   => :body,                             # default [:topic, :body]
  :class_name => "ActsAsMessageable::Message"       # default "ActsAsMessageable::Message"

  #has_many :attributes,:foreign_key => :created_by
  has_many :attribute_values,:foreign_key => :created_by
  has_many :best_uses,:foreign_key => :created_by
  has_many :cons,:foreign_key => :created_by
  has_many :debates,:foreign_key => :created_by
  has_many :items,:foreign_key => :created_by
  has_many :pros,:foreign_key => :created_by
  has_many :reviews,:foreign_key => :created_by
  has_many :contents, :foreign_key => :created_by
  has_many :contents, :foreign_key => :updated_by
  has_many :reports, :foreign_key => :reported_by
  has_many :sent_invitations, :class_name => 'Invitation', :foreign_key => 'sender_id'
  belongs_to :invitation
  belongs_to :facebook
  has_many :field_values
  has_many :flagged_contents, :class_name => 'Flag', :foreign_key => 'flagged_by'
  has_many :verified_contents, :class_name => 'Flag', :foreign_key => 'verified_by'
  #has_attached_file :uploaded_image, :styles => { :medium => "300x300>", :thumb => "100x100>" }
  
  has_attached_file :avatar, 
                    :styles => {  :medium => "120x120>", :thumb => "24x24>" },
                    :storage => :s3,
                    :bucket => ENV['plannto'],
                    :s3_credentials => "config/s3.yml",
                    :path => "images/users/:id/:style/:filename"
  
  after_create :populate_username

  scope :follow_type, lambda { |follow_type| where("follows.follow_type = ?", follow_type)}
  scope :followable_type, lambda { |followable_type| where("follows.followable_type = ?", followable_type).group("follows.follower_id")}
  scope :followable_id, lambda { |followable_id| where("follows.followable_id = ?", followable_id)}
  scope :join_follows, joins("INNER JOIN `follows` ON follows.follower_id = users.id")
  
  scope :friends, lambda {|user| join_follows.followable_type('User').where("follows.follower_id = #{user.id}")}
  
 
  USER_POINTS = {:new_review => {:points => 2,:self_update => true},
    :new_question => {:points => 1,:self_update => true},
    :new_answer => {:points => 1,:self_update => true}
  }

  #has_one :avatar


  has_many :shares;
  
  def self.get_follow_users_id(current_user)
     Follow.where("follower_id=? and followable_type=?",current_user,"User").collect(&:followable_id)
  end
  
  def invitation_token
    invitation.token if invitation
  end

  def invitation_token=(token)
    self.invitation = Invitation.find_by_token(token)
  end

  def get_photo(type = :thumb)
    #unless user_details = $redis.hget("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", "avatar_url")
      #user_details = avatar.photo.url(type) unless avatar.blank?
     # user_details = (@facebook_user.endpoint + "/picture") unless @facebook_user.blank?      
     # $redis.hset("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", "avatar_url", user_details)
   # end
   # user_details
    avatar.url(type)
  end
  
  def get_url()
      "/#{self.username}"
  end
  # def username
  #   email.split("@")[0]
  # end
  
  def self.get_followers(request_url)
    if request_url.match('cars')
      User.join_follows.followable_type('Car').limit(20)
    elsif request_url.match('mobiles')
      User.join_follows.followable_type('Mobile').limit(20)
    elsif request_url.match('bikes')
      User.join_follows.followable_type('Bike').limit(20)
    elsif request_url.match('tablets')
      User.join_follows.followable_type('Tablet').limit(20)
    elsif request_url.match('cycles')
      User.join_follows.followable_type('Cycle').limit(20)
    elsif request_url.match('cameras')
       User.join_follows.followable_type('Camera').limit(20)
     end        
  end
  
  def self.get_followers_count(request_url)
    if request_url.match('cars')
      User.join_follows.followable_type('Car').length
    elsif request_url.match('mobiles')
      User.join_follows.followable_type('Mobile').length
    elsif request_url.match('bikes')
      User.join_follows.followable_type('Bike').length
    elsif request_url.match('tablets')
      User.join_follows.followable_type('Tablet').length
    elsif request_url.match('cycles')
      User.join_follows.followable_type('Cycle').length
    elsif request_url.match('cameras')
       User.join_follows.followable_type('Camera').length
     end        
  end
  
  def self.get_top_contributors 
    ActiveRecord::Base.connection.execute("select user_id, sum(points) from view_top_contributors group by user_id order by sum(points) desc limit 5")
  end
    
  def name
    unless u_name = $redis.hget("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", "name")
      u_name = super
      $redis.hset("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", "name", u_name)
    end
    u_name
    super
  end

  def set_user_follow_item
    CACHE_USER_ITEM_HASH.each do |item_type, cache_key|
      follow_ids = $redis.hexists("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", cache_key)
      if !follow_ids
        follow_items = get_follow_items(item_type)
        $redis.hset("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", cache_key, follow_items) if !follow_items.blank?
      end
    end
  end

  def get_user_follow_item(item_id)
    Struct.new("FollowItem", :follow_type)
    user_item_follow_type = Struct::FollowItem.new("")
    CACHE_USER_ITEM_HASH.each do |item_type, cache_key|
      item_ids = $redis.hget("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", cache_key)
      if !item_ids.blank? && item_ids.split(",").include?(item_id.to_s)
        user_item_follow_type = Struct::FollowItem.new(item_type)
      end
    end
    user_item_follow_type
  end

  def clear_user_follow_item
    CACHE_USER_ITEM_HASH.each do |item_type, cache_key|
      $redis.hdel("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", cache_key)
    end
  end

  def get_follow_items(item_type)
    begin
      (follows.group_by(&:follow_type)[item_type]).map(&:followable_id).join(",")
    rescue
      nil
    end
  end

  def total_points
    Point.find_by_sql("select points from view_rankings where user_id = #{self.id} limit 1").try(:first).try(:points)
  end

  def voted_positive?(item)
    redis_key = "user:#{self.id}:content:#{item.id}:vote"
    vote = $redis.get redis_key
    if vote.nil?
      vote = self.voted_for?(item)      
      $redis.set(redis_key, true) if vote
      return vote
    end
    value =  vote == "true" ? true : false
    return value
  end

  def voted_negative?(item)
    redis_key = "user:#{self.id}:content:#{item.id}:vote"
    vote = $redis.get redis_key
    if vote.nil?
      vote = self.voted_against?(item)      
      $redis.set(redis_key, false) if vote
      return vote
    end
    value =  vote == "false" ? true : false
    return value
  end

  def fetch_content_user_vote?(item)
    value = $redis.get "user_#{self.id}_item_#{item.id}"
    return value.nil? ?  nil : value  
  end

  def follow_facebook_friends
    uids = graph_api.get_connections("me", "friends").map{|fb_friend| fb_friend['id']}
    facebook_users = User.where("uid in (#{uids.join(',')})").all
 
    facebook_users.each do |facebook_user|
      self.follow(facebook_user, 'Facebook')
      facebook_user.follow(self, 'Facebook')
    end
  end
  
  def update_without_current_password(params={})
    params.delete(:current_password) 
    update_attributes(params) 
  end

 def has_no_password?
   self.encrypted_password.blank?
 end
 def total_reviews_count
   self.contents.where("sub_type=?","Reviews").count
 end
 
 def total_items_following_count
   User.join_follows.where("follows.followable_type!=? and follows.follower_id=?",'User',self.id).count
 end
 
  def self.profile_owner?(user,current_user)
    return true if user.id == current_user.id
    return false
  end
  def self.create_from_fb_callback(auth)
    user = User.new(email:auth.info.email, name:auth.extra.raw_info.name, password:Devise.friendly_token[0,20], 
                      uid:auth.uid, token:auth.credentials.token)                 
    user.avatar = open(auth.info.image.gsub('square', 'large')) 
    user.save
    user
  end
  
  def is_moderator?
    self.is_admin?
  end
  
  def facebook_friends
    graph_api.get_connections("me", "friends")
  end
  
  def follow_by_type(obj, type)
    self.follows.where(followable_id: obj.id).where(followable_type: obj.class.to_s).where(follow_type: type).first
  end
  
=begin  
  def self.followers_of(followable_id = nil, followable_type = nil, follow_type = nil)
    conditions = ''
    conditions = conditions + "follows.followable_id = #{followable_id}" unless followable_id.blank?
    conditions = conditions + " AND " unless conditions.blank?
    conditions = conditions + "follows.followable_type = '#{followable_type}'" unless followable_type.blank?
    #conditions = conditions + " AND " unless conditions.blank?
    conditions = conditions + "follows.follow_type = #{follow_type}" unless follow_type.blank?
    
    self.all( :joins => "INNER JOIN `follows` ON follows.follower_id = users.id",
              :conditions => conditions)
  end
=end
  
  #def following_users
    #self.follows.for_followable_type('User').follow_type('Plannto')
  #end
  
  private

  def populate_username
    # Extract email address from Email address provided by user
    user_name = email.split("@")[0]
    user_name = user_name.gsub(".","_")

    #check if the same username is already present in the db
    existing_user_names = User.where("username like ? OR username like ?", "#{user_name}%", "#{user_name}.%")

    if existing_user_names.present?
      # write logic here to increment the last digit of username
      arr = existing_user_names.last.username.split(".")
      if arr.size > 1 
        counter = arr.last.to_i + 1     
        new_username = "#{user_name}.#{counter}"
      else
        new_username = "#{user_name}.1"
      end
      update_attribute(:username, new_username)
    else
      update_attribute(:username, user_name)
    end

  end

  def graph_api
    Koala::Facebook::API.new(self.token)
  end
  
  

end
