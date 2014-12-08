class Account < ActiveRecord::Base
    # many to one relationship with user
    belongs_to :user

    # one to many relationship with transactions
    has_many :transactions

    def close_account(user)
        if user.account_type != "teller"
            if self.user != user
                return sprintf('%s is not allowed to close account %d',
                               user.email, self.account_number)
            end
        end

        if self.closed
            return sprintf('Account %d is already closed', self.account_number)
        end

        if self.balance > 0
            return sprintf('Account %d has a non-zero balance. Please withdraw all funds before closing',
                           self.account_number)
        end

        self.closed = true
        #drop this account from its user, but don't delete this account
        self.user.accounts.delete(self)

        # make a transaction record of the close
        @transaction = Transaction.new
        @transaction.by = user.email
        @transaction.transaction_type = "account closed"
        self.transactions.push @transaction
        self.save

        if self.user.accounts.size <= 0
            puts "USER DESTROYED DOE"
            self.user.destroy
        end

        return sprintf('Account %d has been successfully closed', self.account_number)
    end

    # generic method for keeping track of transactions on this account
    def update_balance(amount, user, type)
        int_amount = (amount * 100).to_i
        float_amount = (int_amount.to_f / 100).to_f
        self.balance += float_amount
        @transaction = Transaction.new
        @transaction.amount = float_amount.to_f
        @transaction.by = user.email
        @transaction.transaction_type = type
        @transaction.balance = self.balance
        self.transactions.push @transaction
        self.save
        return float_amount
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
            amount=to_account.update_balance(amount, user, "transfer from "+self.account_number.to_s)
            return sprintf('Transfer from %d to %d of $%.2f was successful',
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
            return sprintf('%s is not allowed to make deposits for account %d',
                           user.email, self.account_number)
        end

        # check if amount to transfer is more than 0
        if amount <= 0
            return sprintf('Please enter a deposit of more than $0.00')
        end

        amount = self.update_balance(amount, user, "deposit");
        return sprintf('Deposit to account %d of $%.2f was successful',
                       self.account_number, amount) 
    end

    def withdraw(amount, user)
        # check if this user is able to move money from this account
        if user.account_type != "teller"
            if self.user != user
                return sprintf('%s is not allowed to make withdrawals for account %d',
                               user.email, self.account_number)
            end
        end

        # check if amount to transfer is more than 0
        if amount <= 0
            return sprintf('Please enter a withdrawal of more than $0.00')
        end

        if self.balance < amount
            return sprintf('Withdrawal from %d failed. Please check for sufficient funds',
                            self.account_number)
        end

        amount = self.update_balance(-amount, user, "withdrawal");
        return sprintf('Withdrawl from account %d of $%.2f was successful',
                       self.account_number, -amount) 

    end

    def as_json(options={})
        super(:include => [:transactions])
    end
end

