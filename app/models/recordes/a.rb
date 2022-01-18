class Recordes::A < Record
  attr_json :address, :string

  def computed_value
    [Resolv::IPv4.create(address)]
  end
end
