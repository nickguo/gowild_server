class AddInterestDateToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :interest_date, :datetime
  end
end
