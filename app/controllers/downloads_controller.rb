class DownloadsController < ApplicationController
  def index
    filename = "report_#{params[:category]}_#{Time.now.strftime('%d_%b_%Y')}.xml".downcase
    begin
      file_url = "#{configatron.root_image_path}reports/#{params[:category]}/#{filename}"
      data = open(file_url)
      send_data data.read, filename: "plannto_in_amazon_#{params[:category]}_#{Time.now.strftime('%d_%b_%Y')}.xml".downcase, :type => data.content_type, :x_sendfile => true
    rescue Exception => e
      render :text => "Wrong filename => plannto_in_amazon_#{params[:category]}_#{Time.now.strftime('%d_%b_%Y')}.xml OR Not Present"
    end
  end

  def get_download
    # send_file(
    #     "https://planntonew.s3.amazonaws.com/reports/report_07_dec_2016_1481093687.xml?AWSAccessKeyId=AKIAJWDCN4DJWNL2FK5A&Expires=1481112322&Signature=si0fJ4IlwBgmXBeU64KEnhTuXdc%3D&response-content-disposition=attachment%3B%20filename%3Dnew_file.xml",
    #     filename: "plannto_in_amazon_apparel.xml",
    #     type: "application/xml", :x_sendfile => true
    # )
    data = open("#{configatron.root_image_path}reports/report_07_dec_2016_1481093687.xml")
    send_data data.read, filename: "plannto_in_amazon_apparel.xml", :type => data.content_type, :x_sendfile => true

    # send_file "https://planntonew.s3.amazonaws.com/reports/report_07_dec_2016_1481093687.xml?AWSAccessKeyId=AKIAJWDCN4DJWNL2FK5A&Expires=1481112322&Signature=si0fJ4IlwBgmXBeU64KEnhTuXdc%3D&response-content-disposition=attachment%3B%20filename%3Dnew_file.xml", :x_sendfile => true
    # send_file "http://cdn1.plannto.com/reports/report_07_dec_2016_1481093687.xml?AWSAccessKeyId=AKIAJWDCN4DJWNL2FK5A&Expires=1481112322&Signature=si0fJ4IlwBgmXBeU64KEnhTuXdc%3D&response-content-disposition=attachment%3B%20filename%3Dnew_file.xml", :x_sendfile => true
    # redirect_to "#{configatron.root_image_path}reports/report_07_dec_2016_1481093687.xml"
  end
end
