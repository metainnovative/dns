class CreateClients < ActiveRecord::Migration[6.1]
  def change
    create_table :clients do |t|
      t.cidr :ip_address, null: false

      t.timestamps
      t.index :ip_address, unique: true
    end
  end
end
