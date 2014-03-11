class NotificationMailer < ActionMailer::Base
  default from: "\"PlannTo\" <admin@plannto.com>"

  def feed_process_failure(error_message)
    puts "=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=> sending feed process failure mail to admin =>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>"
    @error_message = error_message
    subject = "Cron job failure for feed process at #{Time.now}"
    mail(:to => ["saravana@plannto.com", "siva@plannto.com"], :subject => subject)
  end
end
