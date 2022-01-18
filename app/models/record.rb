class Record < ApplicationRecord
  include AttrJson::Record

  def computed_value
    raise NotImplementedError
  end
end
