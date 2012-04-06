class EventContent < Content
	acts_as_citier

  validates :start_date, :presence => true
  #validates :end_date, :presence => true

  validate :validate_end_date_before_start_date

  def validate_end_date_before_start_date
    logger.info end_date
    if end_date && start_date
      errors.add(:end_date, "should be greater than start date") if end_date < start_date
    end
  end

end
