class Follow < ActiveRecord::Base
  extend ActsAsFollower::FollowerLib
  
  scope :for_follower,        lambda { |follower| where(["follower_id = ? AND follower_type = ?",
                                                         follower.id, parent_class_name(follower)]) }
  scope :for_followable,      lambda { |followable| where(["followable_id = ? AND followable_type = ?",
                                                           followable.id, followable.class.name]) }
  scope :for_follower_type,   lambda { |follower_type| where("follower_type = ?", follower_type) }
  scope :for_followable_type, lambda { |followable_type| where("followable_type = ?", followable_type) }
  scope :for_followable_id, lambda { |followable_id| where("followable_id = ?", followable_id) }
  
  scope :follow_type, lambda{|type| where(follow_type: type)}
  
  scope :recent,              lambda { |from| where(["created_at > ?", (from || 2.weeks.ago).to_s(:db)]) }
  scope :descending,          order("follows.created_at DESC")
  scope :unblocked,           where(:blocked => false)
  scope :blocked,             where(:blocked => true)
  scope :all_follower_type,        lambda { |follower, followable| where(["follower_id = ? AND follower_type = ? AND followable_type = ? AND followable_id = ?",
                                                         follower.id, parent_class_name(follower), followable.class.name, followable.id]) }
  
  
  # NOTE: Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, :polymorphic => true
  belongs_to :follower,   :polymorphic => true

  module ProductFollowType
    Buyer = "buyer"
    Owner = "owner"
    Follow = "follower"
  end
  
  def block!
    self.update_attribute(:blocked, true)
  end

  def self.get_followers(item)
    Follow.for_follower(item).select("count(*) as follow_count, follow_type").group("follow_type")
  end
  
  def self.get_followers_following(user,type)
    if type == "Followers"
       @followers = Follow.follow_type(['Plannto', 'Facebook']).for_followable(user).limit(10).collect{|i| User.find(i.follower_id)}
    else  
      @following =  Follow.where("follower_id=? and followable_type=?",user,"User").limit(10).collect{|i|User.find(i.followable_id)}
    end
  end     

  
  def self.wizard_save(item_ids,type,user)
     item_ids.split(',').uniq.each do |id|
      item = Item.find(id)
      follow = user.follows.new
      follow.followable_id = item.id
      follow.followable_type = item.type
      follow.followable_id = item.id
      follow.follow_type = type
      follow.save
    end 
  end
  #TODO this is not so good. but current implementation of follow forces to do this
  def content?(type)
    ['Apps', 'Accessories'].include?(type)
  end
  
  def content_followable
    Content.find(self.followable_id)
  end
end
