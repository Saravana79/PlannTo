class ExternalContentsController < ApplicationController
#caches_action :show, :unless => :current_user, :cache_path => Proc.new { |c| c.params }
  layout :false
  
  def show
    @content = Content.find(params[:content_id])
    HistoryDetail.create(site_url: @content.url, ip_address: request.remote_ip, redirection_time: Time.now, 
                         user_id: current_user.try(:id), plannto_location: session[:return_to])
  
    frequency = 1
    results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency 1
      boost_by_relevance true
      minimum_word_length 2
      paginate(:page => 1, :per_page => 6)
    end
    @related_contents = results.results
  
  end

end
