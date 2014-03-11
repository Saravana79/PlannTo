# /config/initializer/s3.rb
# if you're using sg buckets
Paperclip.interpolates(:s3_sg_url) { |attachment, style|
   "#{attachment.s3_protocol}://s3-ap-southeast-1.amazonaws.com/#{attachment.bucket_name}/#{attachment.path(style).gsub(%r{^/},
   "")}"
   }

Paperclip.interpolates('imageable_id') do |attachment, style|
  attachment.instance.imageable_id
end