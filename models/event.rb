require 'elasticsearch/model'

class Event < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :creator, class_name: :User
  has_many :appointments
  has_many :team_appointments
  has_many :participants, through: :appointments
  has_many :team_participants, through: :team_appointments
  attr_accessor :repeated_number, :integer
end

Event.import