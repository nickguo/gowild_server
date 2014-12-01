class AddBalancesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :savings_balance,   :float, :default => 10000.00
    add_column :users, :checkings_balance, :float, :default => 2000.00
  end
end
