class RoundParticipant < ActiveRecord::Base
  include FromExperiment
  acts_as_paranoid
  belongs_to :participant
  belongs_to :round
  validates :participant, presence: true
  validates :round, presence: true
  validates :effort_estimate, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :justification, presence: true
end
