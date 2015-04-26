class AdReport < ActiveRecord::Base
  validates_presence_of :from_date, :to_date, :report_type

  belongs_to :advertisement

  def self.generate_report(param, user, advertisement)
    ad_report = advertisement.ad_reports.build
    ad_report.update_attributes!(:from_date => param[:from_date], :to_date => param[:to_date], :report_type => param[:select_by], :status => "processing", :report_date => Time.now, :reported_by => user.id)
    ad_report
  end

  def self.generate_more_report(param, user)
    ad_report = AdReport.where(:from_date => param[:from_date].to_date, :to_date => param[:to_date].to_date, :report_type => param[:type], :status => "processing", :report_date => Date.today, :ad_ids => param[:ad_id]).last

    if ad_report.blank?
      ad_report = AdReport.new
      ad_report.update_attributes!(:from_date => param[:from_date], :to_date => param[:to_date], :report_type => param[:type], :status => "processing", :report_date => Date.today, :reported_by => user.id,
                                   :ad_type => param[:ad_type], :ad_ids => param[:ad_id])
      ad_report
    end
    ad_report
  end

  def filename
    "report_#{self.id}_#{self.from_date.strftime('%d_%b_%Y')}_to_#{self.to_date.strftime('%d_%b_%Y')}.csv".downcase
  end

  def filepath
    "#{configatron.root_image_path}reports/#{filename}"
  end
end
