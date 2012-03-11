class VotingPoint
  @queue = :add_voting_points

  def self.perform(user_id, voteable_id, parent_type)
    voteable = parent_type.camelize.constantize.find(voteable_id)
    user = User.find(user_id)
    $redis.set('voting', 'saving voting point')
    Point.add_voting_point(user, voteable)
    puts "Info: #{$redis.get('voting')}"
  end  
end
