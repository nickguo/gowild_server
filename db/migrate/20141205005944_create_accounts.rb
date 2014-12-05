class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :account_type
      t.float :balance
      t.references :user, index: true
      t.integer :account_number
      t.timestamps
    end
  end
end
