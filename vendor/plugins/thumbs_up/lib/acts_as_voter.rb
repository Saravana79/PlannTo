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
        has_many :votes, :as => :voter, :dependent => :destroy, :conditions => ['vote != ? or vote is not null', ""]

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

      def get_class_name(class_name)
        parent_class_name = case class_name
        when "Tip" then "Content"
        when "VideoContent" then "Content"
        when "QuestionContent" then "Content"
        when "ReviewContent" then "Content"
        when "ArticleContent" then "Content"
        else class_name
        end
        return parent_class_name
      end

      def voted_on?(voteable)
        class_name = get_class_name(voteable.class.name)
        0 < Vote.where(
          :voter_id => self.id,
          :voter_type => self.class.name,
          :voteable_id => voteable.id,
          :voteable_type => class_name
        ).count
      end
      
      def vote_exists?(id)
        Vote.exists? id
      end

      def fetch_updated_vote_count(voteable,direction)
        class_name = get_class_name(voteable.class.name)
        vote = VoteCount.select(:vote_count).where(:voteable_id => voteable.id,:voteable_type => class_name).first
        direction ? vote.vote_count + 1 : vote.vote_count - 1
      end

      def fetch_vote_counter(voteable)
        class_name = get_class_name(voteable.class.name)
        VoteCount.where(:voteable_id => voteable.id,:voteable_type => class_name).first
      end
      
      def fetch_vote(voteable)
        class_name = get_class_name(voteable.class.name)
        Vote.where(
          :voter_id => self.id,
          :voter_type => self.class.name,
          :voteable_id => voteable.id,
          :voteable_type => class_name
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
            #Vote.update(options[:id],:vote => direction)
            vote_obj = Vote.find(options[:id])
            
            vote_count_obj = VoteCount.find(self.fetch_vote_counter(voteable).id)
            if direction == true
              count = vote_count_obj.vote_count_positive + 1
              # if
              negative_count = vote_obj.vote == false ? vote_count_obj.vote_count_negative - 1 : vote_count_obj.vote_count_negative
              #end
              vote_count_obj.update_attributes(:vote_count => self.fetch_updated_vote_count(voteable, direction), :vote_count_positive => count, :vote_count_negative => negative_count)
            else
              count = vote_count_obj.vote_count_negative + 1
              positive_count = vote_obj.vote == true ? vote_count_obj.vote_count_positive - 1 : vote_count_obj.vote_count_positive
              vote_count_obj.update_attributes(:vote_count => self.fetch_updated_vote_count(voteable, direction), :vote_count_negative => count, :vote_count_positive => positive_count)
            end
            vote_obj.update_attributes(:vote => direction)
            #VoteCount.update(self.fetch_vote_counter(voteable).id, :vote_count => self.fetch_updated_vote_count(voteable, direction))
          end
        else
          #:voteable_type => voteable.class.name, :voteable_id => voteable.id,
          Vote.create!(:vote => direction, :voteable => voteable, :voter => self)
          if fetch_vote_counter(voteable).nil?
            VoteCount.create!(:vote_count => (direction ? 1 : -1), :voteable => voteable, :vote_count_positive => (direction ? 1 : 0), :vote_count_negative => (direction ? 0 : 1))
          else
            vote_count_obj = VoteCount.find(self.fetch_vote_counter(voteable).id)
            if direction == true
              count = vote_count_obj.vote_count_positive + 1
              vote_count_obj.update_attributes(:vote_count => self.fetch_updated_vote_count(voteable, direction), :vote_count_positive => count)
            else
              count = vote_count_obj.vote_count_negative + 1
              vote_count_obj.update_attributes(:vote_count => self.fetch_updated_vote_count(voteable, direction), :vote_count_negative => count)
            end
            # VoteCount.update(self.fetch_vote_counter(voteable).id, :vote_count => self.fetch_updated_vote_count(voteable, direction))
          end
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
        class_name = get_class_name(voteable.class.name)
        voted_object = Vote.where(
          :voter_id => self.id,
          :voter_type => self.class.name,
          :voteable_id => voteable.id,
          :voteable_type => class_name
        ).first
        vote_obj = Vote.find(voted_object.id)
        old_vote = vote_obj.vote
        vote_obj.update_attributes(:vote => nil)
        #Vote.update(voted_object.id, :vote => nil)
        unless self.fetch_vote_counter(voteable).nil?
          vote_count_obj = VoteCount.find(self.fetch_vote_counter(voteable).id)
          if old_vote == true
            count = vote_count_obj.vote_count_positive - 1
            vote_count_obj.update_attributes(:vote_count => self.fetch_updated_vote_count(voteable, !direction), :vote_count_positive => count)
          else
            count = vote_count_obj.vote_count_negative - 1
            vote_count_obj.update_attributes(:vote_count => self.fetch_updated_vote_count(voteable, !direction), :vote_count_negative => count)
          end
          #VoteCount.update(self.fetch_vote_counter(voteable).id, :vote_count => self.fetch_updated_vote_count(voteable, !direction)) unless self.fetch_vote_counter(voteable).nil?
        end
      end

      def voted_which_way?(voteable, direction)
        raise ArgumentError, "expected :up or :down" unless [:up, :down].include?(direction)
        class_name = get_class_name(voteable.class.name)
        vote = Vote.where(
          :voter_id => self.id,
          :voter_type => self.class.name,
          #:vote => direction == :up ? true : false,
          :voteable_id => voteable.id,
          :voteable_type => class_name
        )
        if(vote.count == 0)
          return false
        elsif(vote[0].vote == 1 and direction ==:up)
          return true
        elsif(vote[0].vote == 0 and direction ==:down)
          return true
        else
          return false
      end

    end
  end
end