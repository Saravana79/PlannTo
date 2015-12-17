# /config/initializer/s3.rb
# if you're using sg buckets
Paperclip.interpolates(:s3_sg_url) { |attachment, style|
   "#{attachment.s3_protocol}://s3-ap-southeast-1.amazonaws.com/#{attachment.bucket_name}/#{attachment.path(style).gsub(%r{^/},
   "")}"
   }

Paperclip.interpolates('imageable_id') do |attachment, style|
  attachment.instance.imageable_id
end


s3_config = YAML.load_file("#{Rails.root}/config/s3.yml")[Rails.env]

$s3 = AWS::S3.new(
    :access_key_id => s3_config["access_key_id"],
    :secret_access_key => s3_config["secret_access_key"]
)

$s3_object = $s3.buckets[s3_config["bucket"]]