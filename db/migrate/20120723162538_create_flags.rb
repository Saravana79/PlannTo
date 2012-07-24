class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
	  t.references 	:content
	  t.integer		:flagged_by
	  t.string		:type
	  t.text		:reason
	  t.boolean		:verfied
	  t.integer		:verified_by

      t.timestamps
    end
  end
end
