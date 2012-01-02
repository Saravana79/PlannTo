module ThumbsUp #:nodoc:
  module ActsAsVoter #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_voter

        # If a voting entity is deleted, keep the votes.
        # If you want to nullify (and keep the votes), you'll need to remove
        # the unique constraint on the [ voter, voteable ] index in the database.
        # has_many :votes, :as => :voter, :dependent => :nullify
        # Destroy votes when a user is deleted.
        has_many :votes, :as => :voter, :dependent => :destroy

        include ThumbsUp::ActsAsVoter::InstanceMethods
        extend  ThumbsUp::ActsAsVoter::SingletonMethods
      end
    end

    # This module contains class methods
    module SingletonMethods
    end

    # This module contains instance methods
    module InstanceMethods

      # Usage user.vote_count(:up)  # All +1 votes
      #       user.vote_count(:down) # All -1 votes
      #       user.vote_count()      # All votes

      def vote_count(for_or_against = :all)
        v = Vote.where(:voter_id => id).where(:voter_type => self.class.name)
        v = case for_or_against
          when :all   then v
          when :up    then v.where(:vote => true)
          when :down  then v.where(:vote => false)
        end
        v.count
      end

      def voted_for?(voteable)
        voted_which_way?(voteable, :up)
      end

      def voted_against?(voteable)
        voted_which_way?(voteable, :down)
      end

      def voted_on?(voteable)
         0 < Vote.where(
              :voter_id => self.id,
              :voter_type => self.class.name,
              :voteable_id => voteable.id,
              :voteable_type => voteable.class.name
             ).count
      end
      
      def vote_exists?(id)
        Vote.exists? id
      end

      def fetch_updated_vote_count(voteable,direction)
        vote = VoteCount.select(:vote_count).where(:voteable_id => voteable.id,:voteable_type => voteable.class.name).first
        direction ? vote.vote_count + 1 : vote.vote_count - 1
      end

      def fetch_vote_counter(voteable)
        VoteCount.where(:voteable_id => voteable.id,:voteable_type => voteable.class.name).first
      end
      
      def fetch_vote(voteable)
        Vote.where(
              :voter_id => self.id,
              :voter_type => self.class.name,
              :voteable_id => voteable.id,
              :voteable_type => voteable.class.name
             ).first
      end  

      def vote_for(voteable)
        self.vote(voteable, { :direction => :up, :exclusive => false })
      end

      def vote_against(voteable)
        self.vote(voteable, { :direction => :down, :exclusive => false })
      end

      def vote_exclusively_for(voteable)
        self.vote(voteable, { :direction => :up, :exclusive => true })
      end

      def vote_exclusively_against(voteable)
        self.vote(voteable, { :direction => :down, :exclusive => true })
      end

      #example - voter.vote(voteable,:direction => :up)
      def vote(voteable, options = {})
        raise ArgumentError, "you must specify :up or :down in order to vote" unless options[:direction] && [:up, :down].include?(options[:direction].to_sym)
        direction = (options[:direction].to_sym == :up)

#        if options[:exclusive]
#          self.clear_votes(voteable,direction)
#        end

        if options[:id]
          if self.vote_exists?(options[:id]) and !self.voted_which_way? voteable,options[:direction].to_sym
           Vote.update(options[:id],:vote => direction, :voteable => voteable, :voter => self)
           VoteCount.update(self.fetch_vote_counter(voteable).id, :vote_count => self.fetch_updated_vote_count(voteable, direction))
          end
        else
          Vote.create!(:vote => direction, :voteable => voteable, :voter => self)
          VoteCount.create!(:vote_count => (direction ? 1 : -1), :voteable => voteable)
        end
      end

#      #Added new method to update votes - Rahul
#      def update_votes(voteable,vote_id = nil, direction )
#        #raise ArgumentError, "you must specify :up or :down in order to vote" unless options[:direction] && [:up, :down].include?(options[:direction].to_sym)
#        unless self.voted_on?(voteable)
#          self.vote(voteable,options)
#        end
#        vote_id = vote_id || self.vote_id(voteable)
#        direction = (options[:direction].to_sym == :up)
#        Vote.update(:id => vote_id, :vote => direction, :voteable => voteable, :voter => self)
#      end
#
#      #Added new method to fetch the vote id
#      def vote_id(voteable)
#        Vote.where(
#              :voter_id => self.id,
#              :voter_type => self.class.name,
#              :voteable_id => voteable.id,
#              :voteable_type => voteable.class.name
#            ).id
#      end

      def clear_votes(voteable,direction = true)
#        Vote.where(
#          :voter_id => self.id,
#          :voter_type => self.class.name,
#          :voteable_id => voteable.id,
#          :voteable_type => voteable.class.name
#        ).map(&:destroy)
        voted_object = Vote.where(
          :voter_id => self.id,
          :voter_type => self.class.name,
          :voteable_id => voteable.id,
          :voteable_type => voteable.class.name
        ).first
        Vote.update(voted_object.id, :vote => nil)
        VoteCount.update(self.fetch_vote_counter(voteable).id, :vote_count => self.fetch_updated_vote_count(voteable, !direction)) unless self.fetch_vote_counter(voteable).nil? 
      end

      def voted_which_way?(voteable, direction)
        raise ArgumentError, "expected :up or :down" unless [:up, :down].include?(direction)
        0 < Vote.where(
              :voter_id => self.id,
              :voter_type => self.class.name,
              :vote => direction == :up ? true : false,
              :voteable_id => voteable.id,
              :voteable_type => voteable.class.name
            ).count
      end

    end
  end
end