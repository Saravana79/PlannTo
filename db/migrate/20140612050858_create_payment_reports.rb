class CreatePaymentReports < ActiveRecord::Migration
  def change
    create_table :payment_reports do |t|
      t.integer :publisher_id
      t.datetime :payment_date
      t.float :commission_amount
      t.float :tax_amount
      t.float :final_amount
      t.string :payment_method

      t.timestamps
    end
  end
end
