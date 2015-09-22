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
end