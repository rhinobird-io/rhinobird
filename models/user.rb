
require "bcrypt"

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not an email")
    end
  end
end

class User < ActiveRecord::Base

  include BCrypt

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, email: true

  has_many :users_teams, dependent: :destroy
  has_many :teams, :through => :users_teams
  has_many :dashboard_records, -> {order 'created_at DESC'}
  has_many :notifications, -> {order 'created_at ASC'}
  has_one :local_avatar, dependent: :destroy
  has_many :appointments, foreign_key: :participant_id
  has_many :events, through: :appointments

  def password
    @password ||= Password.new(encrypted_password)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.encrypted_password = @password
  end
end