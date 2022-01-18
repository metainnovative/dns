class AddOwnerToDomains < ActiveRecord::Migration[6.1]
  def change
    change_table :domains do |t|
      t.references :owner, polymorphic: true
      t.remove_index 'digest("value", \'sha1\'::text)', unique: true
      t.index 'digest("value", \'sha1\'::text), owner_type, owner_id', unique: true
    end
  end
end
