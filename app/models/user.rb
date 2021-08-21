class User < ApplicationRecord
  devise :database_authenticatable, :validatable, :lockable
end
