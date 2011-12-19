class Message < ActiveRecord::Base
  attr_reader :message_users_tokens

  def message_users_tokens=(ids)
    self.user_ids = ids.split(",")
  end
end