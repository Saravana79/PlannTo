class Invitation < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User'
  belongs_to :item
  has_one :recepient, :class_name => 'User'
  
  validates_presence_of :email
 
  before_create :generate_token
  
  def accept(user)
    self.transaction do
      user.follow(item, self.follow_type)
      user.clear_user_follow_item
      self.update_attributes(:token => '')
    end
  end
  
  private
 
  def generate_token
    self.token = Digest::SHA1.hexdigest([Time.now, rand].join)
  end
 
end
