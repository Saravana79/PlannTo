require 'acts_as_follower'
module ActsAsFollower
  module Follower

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_follower
        has_many :follows, :as => :follower, :dependent => :destroy
        include ActsAsFollower::Follower::InstanceMethods        
        include ActsAsFollower::FollowerLib
      end
    end
    
    module InstanceMethods
      def follow(followable, follow_type=nil)
        follow = get_follow(followable)
        if follow.blank? && self != followable
          Follow.create(:followable_type => followable.class.name, :followable_id => followable.id,
                        :follower_type => self.class.name, :follower_id => self.id, :follow_type => follow_type)
        end
      end
    end
  end
end


