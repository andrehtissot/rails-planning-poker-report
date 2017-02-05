class Estimate < ActiveRecord::Base
  include FromExperiment
  acts_as_paranoid
  belongs_to :team
  belongs_to :requirement
  has_many :rounds
end
