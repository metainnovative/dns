class Recordes::Aaaa < Record
  attr_json :address, :string

  def computed_value
    [Resolv::IPv6.create(address)]
  end
end
