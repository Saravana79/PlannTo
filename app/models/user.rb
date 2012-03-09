class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

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
    return avatar.photo.url(type) unless avatar.blank?
    return (@facebook_user.endpoint + "/picture") unless @facebook_user.blank?
    return "/images/photo_profile.png"
  end

  def total_points
    Point.find_by_sql("select points from view_rankings where user_id = #{self.id} limit 1").try(:first).try(:points)
  end

end
