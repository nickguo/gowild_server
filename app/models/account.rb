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
    def update_interest_or_penalty(user)
        if user.account_type != "teller"
            return sprintf('%s is not allowed to grant interests or penalties %d',
                           user.email)
        end

        # calculate how many seconds have passed since the last time interest was updated
        seconds = Time.now.to_i - self.interest_date.to_i

        # get the time passed in days now --> real days per second = 86400
        seconds_per_day = 5; # 5 = 'seconds per day' to use instead to quicken testing
        days = seconds / seconds_per_day; 

        # check if interest was already granted today
        if days == 0
            return sprintf('Account has already been updated today')
        end

        # check if '30 days' are up for the period
        period = 30
        if days < period
            return sprintf('Interest/penalty period is not yet over. %d of %d days have passed.',
                           days, period)
        end

        # get all transactions in the range from last updated to now
        @transactions = self.transactions.where(created_at: self.interest_date .. Time.now)

        # order the transactions by the time that they were executed 
        @transactions.order(:created_at)

        # we want to find the average balance over the period
        @average_balance = 0

        # check if there were no transactions in the period -> avg. balance never changed
        if @transactions.size == 0
            @average_balance = self.balance
        else
            # calculate the running balance by calculating the balance at the end of each day
            # --> done by iterating over the days and using transaction history

            # running balance for each of the days
            total_balance = 0 
            # initalize prev_balance to be the balance before the first transaction
            prev_balance = @transactions.first.balance - @transactions.first.amount
            prev_balance_init = prev_balance
            # the starting time for day 0 (starting from the end of previous interest date)
            time_i = self.interest_date.to_i

            cur_day = 0

            while cur_day < days
                # get all of the transactions of this day period from the initial transaction query
                transactions_i = @transactions.where(created_at:
                                                        Time.at(time_i + cur_day*seconds_per_day) ..
                                                        Time.at(time_i + (cur_day+1)*seconds_per_day))

                # if any transactions occurred during this day, update the balance to be the final one of the day
                # otherwise, if no transactions, prev_balance doesn't change.
                # also have to check to see if first transaction was alone since we have already accounted for head balances
                if transactions_i.size > 0
                    prev_balance = transactions_i.last.balance
                end

                # update the total balance and the time for i
                total_balance += prev_balance
                cur_day += 1
            end

            # average balance is the total running balance divided by days
            @average_balance = total_balance / days
        end


        # detailed message:
        #return sprintf('Account %d granted interest of $%.2f, with %d transactions',
        #                self.account_number, 0, @transactions.length)
        # regular message:
               
        # set new time stamp a few seconds back so that the interest becomes latest
        self.interest_date = Time.at(Time.now.to_i - 2)
        self.save

        if @average_balance < 100
            penalty = self.update_balance(-25, user, "Penalty for low balance")
            return sprintf("%d penalized $%.2f for low balance over %d days",
                           self.account_number, penalty, days)
        else
            interest = 0
            if @average_balance > 3000
                interest = self.account_type == "checkings" ? 0.03 : 0.04
            elsif @average_balance > 2000
                interest = self.account_type == "checkings" ? 0.02 : 0.03 
            elsif @average_balance > 1000
                interest = self.account_type == "checkings" ? 0.01 : 0.02
            end

            amount = self.update_balance(interest * @average_balance, user, "Interest")
            return sprintf("%d granted $%.2f for %.2f percent interest on
                            average balance $%.2f for %d days",
                           self.account_number, amount, interest, @average_balance, days)
        end
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

