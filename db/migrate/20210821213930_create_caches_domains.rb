class CreateCachesDomains < ActiveRecord::Migration[6.1]
  def change
    create_table :caches_domains do |t|
      t.references :cache, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.datetime :last_updated_at, null: false, precision: 6

      t.timestamps
      t.index %w[cache_id domain_id], unique: true
    end
  end
end
