class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :name, :remember_me, :facebook_id
  attr_accessor :follow_type
  acts_as_followable
  acts_as_follower

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
  belongs_to :facebook

  # USER_POINTS = {:new_review => 2,:new_question => 1, :new_answer => 1}

  USER_POINTS = {:new_review => {:points => 2,:self_update => true},
                 :new_question => {:points => 1,:self_update => true}, 
                 :new_answer => {:points => 1,:self_update => true}
                }

end
