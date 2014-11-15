class AdReport < ActiveRecord::Base
  belongs_to :advertisement

  def self.generate_report(param, user, advertisement)
    ad_report = advertisement.ad_reports.build
    ad_report.update_attributes!(:from_date => param[:from_date], :to_date => param[:to_date], :report_type => param[:select_by], :status => "processing", :report_date => Time.now, :reported_by => user.id)
    ad_report
  end
end
