class Client < ApplicationRecord
  has_many :domains, as: :owner, dependent: :destroy
  has_many :caches_domains, through: :domains
  has_many :caches, source: :cache, through: :caches_domains

  validates :ip_address, presence: true, uniqueness: true
end
