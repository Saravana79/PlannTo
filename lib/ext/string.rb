class String
  def is_an_integer?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end
end