class Cache < ApplicationRecord
  has_many :caches_domains, dependent: :destroy
  has_many :domains, through: :caches_domains

  validates :type, presence: true
  validates :value, presence: true, uniqueness: { scope: :type }

  scope :block, -> { where(type: 'Caches::Block') }
  scope :permit, -> { where(type: 'Caches::Permit') }
  scope :client, ->(client) {
    conditions = CachesDomain.global
    conditions = conditions.or(CachesDomain.client(client))

    where(id: conditions.select(:cache_id))
  }

  before_validation if: ->() { last_updated_at.nil? } do
    self.last_updated_at = Time.now.utc
  end

  def self.blocked?(domain)
    return false if Cache::Permit.where(value: domain).any?

    Cache::Block.where(value: domain).any?
  end

  def self.permitted?(domain)
    !blocked?(domain)
  end
end
