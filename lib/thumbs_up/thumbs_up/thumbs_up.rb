require "#{Rails.root}/lib/thumbs_up/thumbs_up/acts_as_voteable"
require "#{Rails.root}/lib/thumbs_up/thumbs_up/acts_as_voter"
require "#{Rails.root}/lib/thumbs_up/thumbs_up/has_karma"

ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoteable)
ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoter)
ActiveRecord::Base.send(:include, ThumbsUp::Karma)