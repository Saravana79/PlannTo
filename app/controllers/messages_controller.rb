class MessagesController < ApplicationController
  
  def index
    @user = current_user
    @inbox = current_user.received_messages
  end

  def new
    
  end

  def create_message
    @emails = params[:message][:to].split(",") rescue []
    if @emails.empty?
      flash[:error] = 'Error in Sending Message. No Receivers'
      return redirect_to :back
    end
    @emails.each do |email|
      send_message(email)
    end
    redirect_to messages_path, :notice => 'Message sent.'
  end


  def reply
    @user = User.find(params[:id])
  end

  def send_message(email)
    user_to = User.find_by_email(email)
    message = current_user.send_message(user_to, { :body => params[:message][:body] })
    return
  end



  
end
