class CreateRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :records do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.jsonb :json_attributes, null: false

      t.timestamps
    end
  end
end
