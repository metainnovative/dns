module Domains::PermitConcern
  extend ActiveSupport::Concern

  def cache_klass
    Caches::Permit
  end
end
