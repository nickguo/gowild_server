class AddClosedAndOwnerToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :closed, :boolean
    add_column :accounts, :owner, :string
  end
end
