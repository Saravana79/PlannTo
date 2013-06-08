class CreateAttributeComparisonLists < ActiveRecord::Migration
  def change
    create_table :attribute_comparison_lists do |t|
      t.string :title
      t.integer :attribute_id
      t.integer :itemtype_id
      t.string :value
      t.string :condition
      t.text :description
      t.timestamps
    end
      AttributeComparisonList.create(title: 'Light weight',
                                 attribute_id: 101,
                                 itemtype_id: 6,
                                 value: '',
                                 condition: 'LeserThan',
                                 description: '{1} is {percentage} lighter then {2}, lighter mobile are easier to carry.')
	  AttributeComparisonList.create(title: 'Processor',
	  								 attribute_id: 108,
	  								 itemtype_id: 6,
	  								 value: '',
	  								 condition: 'GreaterThan',
	  								 description: '{1} is having {percentage} more processing capacity then {2}. More processor is more power.')
	  AttributeComparisonList.create(title: 'Has Radio', 
	  								 attribute_id: 6,
	  								 itemtype_id: 6,
	  								 value: 'True',
	  								 condition: 'Equal',
	  								 description: '{1} is having FM Radio')
  end

  # populate Data

end
