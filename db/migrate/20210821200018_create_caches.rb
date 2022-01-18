class CreateCaches < ActiveRecord::Migration[6.1]
  def change
    create_table :caches do |t|
      t.string :type, null: false
      t.string :value
      t.integer :caches_domains_count, null: false, default: 0
      t.datetime :last_updated_at, null: false, precision: 6

      t.timestamps
      t.index :type
      t.index %i[type id]
      t.index 'digest("value", \'sha1\'::text), "type"', unique: true
    end
  end
end
