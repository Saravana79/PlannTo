class MessagesController < ApplicationController

  before_filter :authenticate_user!

  def index
    @user = current_user
    @inbox = current_user.received_messages.group(:sent_messageable_id)
  end

  def new
    
  end

  def show
    @message_users = User.find(:all, :conditions => ['name like ?',"%#{params[:q]}%"])
    respond_to do |format|
      format.html
      format.json { render :json => @message_users.map(&:attributes)}
    end
  end

  def create_message
    @emails = params[:message][:to].split(",") rescue []
    if @emails.empty? and params[:method] == 'new'
      flash[:error] = 'Error in Sending Message. No Receivers'
      return redirect_to :back
    end
    if params[:method] == 'reply'
      user_to = User.find(params[:id])
      message = current_user.send_message(user_to, { :body => params[:message][:body] })
    else
      @emails.each do |email|
        send_message(email)
      end
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

  def block_user
    @opponent = User.find(params[:id])
    current_user.block(@opponent)
    @block_state = true
    @inbox = current_user.received_messages
    respond_to do |format|
      format.html {  }
      format.js {
        render :partial => "messages/message_list", :local => [:inbox => @inbox]
      }
    end
  end

  def threaded_msg
    @sender = User.find(params[:id])
    @messages = Array.new
    @send_msg = current_user.messages.are_to(@sender)
    @received_msg = current_user.messages.are_from(@sender)
    @messages = @send_msg + @received_msg
    @messages = @messages.sort_by &:created_at
  end
end
