class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :by
      t.float :amount
      t.string :transaction_type
      t.references :account, index: true
      t.timestamps
    end
  end
end
