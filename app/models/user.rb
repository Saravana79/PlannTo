class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  REDIS_USER_DETAIL_KEY_PREFIX = "user_details_"

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :name, :remember_me, :facebook_id, :invitation_id, :invitation_token
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
  has_many :sent_invitations, :class_name => 'Invitation', :foreign_key => 'sender_id'
  belongs_to :invitation
  belongs_to :facebook


  USER_POINTS = {:new_review => {:points => 2,:self_update => true},
    :new_question => {:points => 1,:self_update => true},
    :new_answer => {:points => 1,:self_update => true}
  }

  has_one :avatar


  has_many :shares;
  
  def invitation_token
    invitation.token if invitation
  end

  def invitation_token=(token)
    self.invitation = Invitation.find_by_token(token)
  end

  def get_photo(type = :thumb)
    unless user_details = $redis.hget("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", "avatar_url")
      user_details = avatar.photo.url(type) unless avatar.blank?
      user_details = (@facebook_user.endpoint + "/picture") unless @facebook_user.blank?
      user_details = "/images/photo_profile.png" if user_details.blank?
      $redis.hset("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", "avatar_url", user_details)
    end
    user_details
  end

  def name
    unless u_name = $redis.hget("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", "name")
      u_name = super
      $redis.hset("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{id}", "name", u_name)
    end
    u_name
    super
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

end
