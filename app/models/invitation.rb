class Invitation < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User'
  belongs_to :item
  has_one :recepient, :class_name => 'User'
  
  validates_presence_of :email
  validate :recipient_is_not_registered

  before_create :generate_token
  
  private
  
  def recipient_is_not_registered
    errors.add :email, 'is already registered' if User.find_by_email(email)
  end
  
  
  def generate_token
    self.token = Digest::SHA1.hexdigest([Time.now, rand].join)
  end
  
end
