class ItemProCon < ActiveRecord::Base
	belongs_to :pro_con_category
	belongs_to :item
	belongs_to :article_content

	attr_accessible :item_id, :article_cintent_id, :pro_con_category_id, :text, :index, :proorcon
end
