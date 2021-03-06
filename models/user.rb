
require "bcrypt"

class User < ActiveRecord::Base

  include BCrypt

  validates :realname, presence: true
  validates :email, presence: true, email: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates_format_of :name, with: /[A-Za-z]\w*/

  has_many :users_teams, dependent: :destroy
  has_many :teams, :through => :users_teams
  has_many :dashboard_records, -> {order 'created_at DESC'}
  has_many :notifications, -> {order 'created_at DESC'}
  has_one :local_avatar, dependent: :destroy
  has_many :appointments, foreign_key: :participant_id
  has_many :events, through: :appointments

  def get_all_teams
    (self.teams + self.teams.map{|t| t.get_all_parent_teams}.flatten).uniq
  end

  def get_all_not_trashed_events
    (self.events.where('status <> ?', Event.statuses[:trashed]) + self.get_all_teams.map { |t| t.events.where('status <> ?', Event.statuses[:trashed]) }.flatten).uniq
  end

  def password
    @password ||= Password.new(encrypted_password)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.encrypted_password = @password
  end
end