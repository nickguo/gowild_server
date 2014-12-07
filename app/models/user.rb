class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable

    # one to many relationship with accounts
    has_many :accounts

    # temporary instance vars that are used for transfers
    attr_accessor :from_account, :to_account

    def create_account(account_type)
        @account = Account.new
        @account.balance = 0
        @account.account_type = account_type
        @account.account_number = rand(1290000000 .. 1299999999)
        @account.interest_date = Time.now
        # loop to find a new account in case account id was already used
        while Account.find_by_account_number(@account.account_number)!= nil
            @account.account_number = rand(1290000000 .. 1299999999)
        end
        self.accounts.push @account
        self.save
        return @account.account_number
    end
end
