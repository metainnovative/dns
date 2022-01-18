class Recordes::Mx < Record
  attr_json :preference, :exchange

  def computed_value
    [preference, Resolv::DNS::Name.create(exchange)]
  end
end
