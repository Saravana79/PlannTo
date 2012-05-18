class Avatar < ActiveRecord::Base
  belongs_to :user
  has_attached_file :photo, 
  :styles => { :medium => "300x300>", :thumb => "100x100>", :small => "25x25>" },
   :storage => :s3,
    :bucket => ENV['plannto'],
    :s3_credentials => {
      :access_key_id => ENV['AKIAJWDCN4DJWNL2FK5A'],
      :secret_access_key => ENV['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']
      	}
end
