class Account < ActiveRecord::Base
    # many to one relationship with user
    belongs_to :user

    # one to many relationship with transactions
    has_many :transactions

    def update_balance(amount, user, type)
        self.balance += amount
        @transaction = Transaction.new
        @transaction.amount = amount
        @transaction.by = user.email
        @transaction.transaction_type = type
        self.transactions.push @transaction
        self.save
    end
end
