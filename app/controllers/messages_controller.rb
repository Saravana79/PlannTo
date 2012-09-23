class MessagesController < ApplicationController
  layout "product"

  before_filter :authenticate_user!

  def index
    @user = current_user
    @inbox = current_user.received_messages.group(:sent_messageable_id)
  end

  def new
    
  end

  def show
    @message_users = User.find(:all, :conditions => ['name like ? and id !=?',"%#{params[:q]}%", current_user.id])
    respond_to do |format|
      format.html
      format.json { render :json => @message_users.map(&:attributes)}
    end
  end

  def create_message
    @ids = params[:message][:email_list].split(",") rescue []
    if @ids.empty? and params[:method] == 'new'
      flash[:error] = 'Error in Sending Message. No Receivers'
      return redirect_to :back
    end
    if params[:method] == 'reply'
      user_to = User.find(params[:id])
      message = current_user.send_message(user_to, { :body => params[:message][:body] })
    else
      @ids.each do |id|
        send_message(id)
      end
    end
    redirect_to messages_path, :notice => 'Message sent.'
  end

  def reply
    @user = User.find(params[:id])
  end

  def send_message(id)
    user_to = User.find(id)
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
  
   def search_users
    #
     @message_users = User.find(:all, :conditions => ['email like ? and id !=?',"%#{params[:term]}%", current_user.id])

       results = @message_users.collect{|item|
         logger.info item.email
      {:id => item.id, :value => "#{item.email}", :imgsrc =>"", :type => "", :url => "" }
    }
    render :json => results
  end

end
