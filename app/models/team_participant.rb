class TeamParticipant < ActiveRecord::Base
  include FromExperiment
  acts_as_paranoid
  belongs_to :participant
  belongs_to :team
end
