class AlterVendors < ActiveRecord::Migration
  def up
    rename_table :vendors, :vendor_details
    itemtype = Itemtype.find_by_itemtype("Vendor")
    VendorDetail.all.each do |v|
      vendor = Vendor.create(:name => v.name,:imageurl => v.imageurl,:itemtype_id => itemtype.id)
      v.update_attribute('item_id',vendor.id)
    end  
  end

  def down
    rename_table :vendor_details, :vendors
  end
end
