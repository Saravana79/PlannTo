class OauthController < ApplicationController  
   
  def new
    session[:at]=nil
    redirect_to authenticator.authorize_url(:scope => 'publish_stream', :display => 'page')
  end
  
  def create    
    mogli_client = Mogli::Client.create_from_code_and_authenticator(params[:code],authenticator)
    session[:at]=mogli_client.access_token
    redirect_to content_post_path
   end
 
 def content_post
    client = Mogli::Client.new(session[:at])
    content = Content.find(session[:content_id])
    session[:content_id] = ""
    post_data = {}
    post_data[:name] = content.title
    post_data[:link] = "http://www.plannto.com/contents/#{content.id}"
    post_data[:caption] = content.user.name + " shared a " +  content.sub_type.singularize +  " on " + content.items.first.name + " in PlannTo "
    post_data[:description] = ActionView::Base.full_sanitizer.sanitize(content.description)[0..90]
    if !content.content_photo.nil?
      post_data[:picture] = content.content_photo.photo.url(:thumb)
    end   
    post_data[:actions] = { :name => 'Plannto', :link => 'http://www.plannto.com/'}.to_json
    client.post("feed", nil, post_data)
    redirect_to "#{session[:return_to]}"
 end 
  
  def authenticator
    @authenticator ||= Mogli::Authenticator.new('493135047369168', 
                                         'eb773d85c636d3ffc7708b1a5e5391cb', 
                                         oauth_callback_url)
                                         
 end
end
