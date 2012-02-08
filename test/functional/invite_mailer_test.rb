require 'test_helper'

class InviteMailerTest < ActionMailer::TestCase
  test "invite_by_email" do
    mail = InviteMailer.invite_by_email
    assert_equal "Invite by email", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
