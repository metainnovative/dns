class Recordes::Txt < Record
  attr_json :strings, :string, array: true

  def computed_value
    [strings.first, strings.drop(1)]
  end
end
