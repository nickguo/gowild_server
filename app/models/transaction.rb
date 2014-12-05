class Transaction < ActiveRecord::Base
    # many to one relationship with account
    belongs_to :account
end
