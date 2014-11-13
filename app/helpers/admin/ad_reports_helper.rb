module Admin::AdReportsHelper

  def get_ectr(clicks, impressions)
    ((clicks.to_f/impressions.to_f)*100).round(2)
  end
end
