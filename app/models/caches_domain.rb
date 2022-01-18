class CachesDomain < ApplicationRecord
  belongs_to :cache, counter_cache: true, touch: true
  belongs_to :domain, counter_cache: true

  validates :cache_id, uniqueness: { scope: :domain_id }

  scope :global, -> { where(domain: Domain.global) }
  scope :client, ->(client = nil) { where(domain: Domain.client(client)) }

  before_validation if: ->() { last_updated_at.nil? } do
    self.last_updated_at = Time.now.utc
  end

  after_commit on: :destroy, if: -> { cache.domains.empty? } do
    cache.destroy
  end
end
