class SharesController < ApplicationController
   def create
      @item = Item.find(params[:car_id])
      if params['share']['url'].nil?
        @share = @item.shares.create(params[:share])
      else
              url = params['share']['url']
              user_description = params['share']['user_description']
              @share = @item.shares.create(:url => url, :user_description => user_description)
              youtube_content = params['share']['youtube'] 
             # Following block for youtube
             if youtube_content
                      client = YouTubeIt::Client.new
                      require 'youtube_it'  
                      video_id = (@share.url.split('v=')[1]).split('&')[0]
                      @share.youtube = video_id
                      youtube_data = client.video_by(video_id)
                      @share.title = youtube_data.title if youtube_data.title
                      @share.description = youtube_data.description if youtube_data.description
                      @share.thumbnail = youtube_data.thumbnails.first.url if youtube_data.thumbnails.first.url
             else 
             # Following block for article
                       require 'nokogiri'
                       require 'open-uri'
                       begin
                               doc = Nokogiri::HTML(open(url))
                               @title_info = doc.xpath('.//title')
                            doc.xpath("//meta[@name='keywords']/@content").each do |attr|
                               @meta_keywords = attr.value
                            end
                            doc.xpath("//meta[@name='description']/@content").each do |attr|
                               @meta_description = attr.value
                            end
                            doc.xpath("//link[@rel='image_src']/@href").each do |attr|
                               @meta_image = attr.value
                            end
                             @share.title = @title_info.to_s.gsub(%r{</?[^>]+?>}, '') if @title_info
                             @share.description = @meta_description if @meta_description
                             @share.thumbnail = @meta_image   if @meta_image
                      rescue => e
                      end       
              end 
      end
    respond_to do |format|
      if @share.save!
        # format.html { redirect_to(@share, :notice => 'Share was successfully created.') }
         format.html { redirect_to product_path(@item) }
        format.js
        #format.xml  { render :xml => @share, :status => :created, :location => @share }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @share.errors, :status => :unprocessable_entity }
      end
  end     
      #@share.save!
      #redirect_to product_path(@item)
  end
end

