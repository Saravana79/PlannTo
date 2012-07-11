class Invitation < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User'
  belongs_to :item
  has_one :recepient, :class_name => 'User'
  
  validates_presence_of :email
 
  before_create :generate_token
  
  def accept(user)
    self.transaction do
 
      #self.update_attributes(:token => '', :accepted_at => Time.now)
    end
  end
  
  private
 
  def generate_token
    self.token = Digest::SHA1.hexdigest([Time.now, rand].join)
  end
 
end
