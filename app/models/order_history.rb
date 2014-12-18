class OrderHistory < ActiveRecord::Base
  validates :order_date, :total_revenue, :vendor_ids, presence: true

  belongs_to :add_impression, :foreign_key => :impression_id
  belongs_to :vendor, :foreign_key => :vendor_ids
  belongs_to :payment_report
  belongs_to :advertisement
  after_save :create_record_in_m_order_history

  private

  def create_record_in_m_order_history
    imp_id = self.impression_id
    imp = AdImpression.where(:_id => imp_id).last
    unless imp.blank?
      m_order_history = imp.m_order_histories.where(:order_history_id => self.id).last
      unless m_order_history.blank?
        m_order_history.total_revenue = self.total_revenue
        m_order_history.save
      else
        imp.m_order_histories << MOrderHistory.new(:order_history_id => self.id, :total_revenue => self.total_revenue)
      end
    end
  end
end
