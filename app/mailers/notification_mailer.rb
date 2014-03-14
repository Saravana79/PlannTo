class NotificationMailer < ActionMailer::Base
  default from: "\"PlannTo\" <saravana@plannto.com>"

  def resque_process_failure(error_message, log, error_for)
    log.debug "=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=> sending #{error_for} failure mail to admin team =>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>"
    @error_message = error_message
    @error_for = error_for
    subject = "Resque process failure for #{error_for} at #{Time.now}"
    mail(:to => ["saravana@plannto.com", "siva@plannto.com"], :subject => subject)
  end
end
