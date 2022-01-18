module Domains::BlockConcern
  extend ActiveSupport::Concern

  def cache_klass
    Caches::Block
  end
end
