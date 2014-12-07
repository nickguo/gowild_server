class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable

    # one to many relationship with accounts
    has_many :accounts

    # temporary instance vars that are used for transfers
    attr_accessor :from_account, :to_account
end
