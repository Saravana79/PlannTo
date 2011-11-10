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
        else
          follow.update_attribute(:follow_type, follow_type)
        end
      end      
    end
  end
end

module ActsAsFollower #:nodoc:
  module Followable
    module InstanceMethods
      def followers_by_type(follower_type, options={})        
        follows = follower_type.constantize.
          includes(:follows).
          where('blocked = ?', false).
          where(
            "follows.followable_id = ? AND follows.followable_type = ? AND follows.follower_type = ?",
            self.id, self.class.name, follower_type 
          )
        if options.has_key?(:limit)
          follows = follows.limit(options[:limit])
        end
        if options.has_key?(:where)
          follows = follows.where(options[:where])        
        end
        follows
      end
    end
  end
end


