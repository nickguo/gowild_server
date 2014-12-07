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
        @transaction.balance = self.balance
        self.transactions.push @transaction
        self.save
    end

    def transfer(to_account, amount, user)
        # check if this user is able to move money from this account
        if user.account_type != "teller"
            if self.user != user
                return sprintf('%s is not allowed to make transfers for account %d',
                               user.email, self.account_number)
            end
        end

        # check if transferring to the same account
        if to_account == self
            return sprintf('Account %s cannot transfer to itself',
                           self.account_number)
        end

        # check if amount to transfer is more than 0
        if amount <= 0
            return sprintf('Please enter a transfer of more than $0.00')
        end

        if self.balance >= amount
            self.update_balance(-amount, user, "transfer to "+to_account.account_number.to_s)
            to_account.update_balance(amount, user, "transfer from "+self.account_number.to_s)
            return sprintf('Transfer from %d to %d of %.2f was successful',
                           self.account_number, to_account.account_number, amount) 
        else
            return sprintf('Transfer from %d failed. Please check for sufficient funds',
                           self.account_number)
        end
    end

    #TODO
    def update_interest(user)
        if user.account_type != "teller"
            return sprintf('%s is not allowed to grant interest %d',
                           user.email)
        end

        seconds = Time.now.to_i - self.interest_date.to_i
        days = seconds / 10; #TODO change this constant to real time

        if days == 0
            return sprintf('Account has already been updated today')
        end

        # get all transactions in the range from 
        @transactions = self.transactions.where(created_at: self.interest_date .. Time.now)
        @transactions.order(:created_at)

        @balance

        self.interest_date = Time.now
        self.save

        return sprintf('Account %d granted interest of $%.2f, with %d transactions',
                        self.account_number, 0, @transactions.length)
    end

    def deposit(amount, user)
        # check if this user is able to move money from this account
        if user.account_type != "teller"
            if self.user != user
                return sprintf('%s is not allowed to make deposits for account %d',
                               user.email, self.account_number)
            end
        end

        # check if amount to transfer is more than 0
        if amount <= 0
            return sprintf('Please enter a deposit of more than $0.00')
        end

        self.update_balance(amount, user, "deposit");
        return sprintf('Deposit to account %d of %.2f was successful',
                       self.account_number, amount) 
    end

    def as_json(options={})
        super(:include => [:transactions])
    end
end

