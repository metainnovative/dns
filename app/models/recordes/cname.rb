class Recordes::Cname < Record
  attr_json :value, :string

  def computed_value
    [Resolv::DNS::Name.create(value)]
  end
end
