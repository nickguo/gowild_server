class Account < ActiveRecord::Base
    # many to one relationship with user
    belongs_to :user
end
