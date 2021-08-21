# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string   :email,              null: false, default: ''
      t.string   :encrypted_password, null: false, default: ''
      t.integer  :failed_attempts, default: 0, null: false
      t.datetime :locked_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
  end
end
