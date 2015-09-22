class ItemBeautyDetail < ActiveRecord::Base
  validates_uniqueness_of :url

  has_one :vendor, :primary_key => "site", :foreign_key => "id"
  has_one :image, as: :imageable

  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 2.0,  :as => :name_ac do |item|
      tempName = item.name.gsub("-","")

      tempName
    end

    text :nameformlt do |item|
      item.name.to_s.gsub("-", "")
    end

    string :status

    time :created_at
  end

  def get_vendor_name
    return_val = nil
    begin
      vendor_id = self.site
      vendor = Vendor.where(:id => vendor_id).first
      vendor_name = vendor.vendor_detail.name rescue ""
      return_val = vendor_name
    rescue Exception => e
      p "Error while getting vendor name"
      return_val = vendor_name
    end
    return_val
  end
end