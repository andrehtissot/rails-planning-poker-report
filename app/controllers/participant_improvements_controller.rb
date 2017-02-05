class ParticipantImprovementsController < ApplicationController
  before_action :set_teams_by_experiment, only: [:participants_comparison]
  before_action :set_participants_by_experiment, only: [:participants_comparison_independent]

  def index
  end

  def participants_comparison
  end

  def participants_comparison_independent
  end

  private
  def set_participants_by_experiment
    @participants_by_experiment = []
    used_names = []
    participants = []
    1.upto(4).each do |experiment|
      [1,2].each do |step|
        FromExperiment.set_all_db(experiment, step)
        Participant.set_db(experiment, step).all.each do |participant|
          name = "#{participant.name} (#{participant.id})"
          next if used_names.include? name
          used_names << name
          participant = participant.experiment(Participant.experiment).step(Participant.step)
          participants << participant
        end
      end
      @participants_by_experiment << (participants.sort { |a,b| a.name.downcase <=> b.name.downcase })
      participants = []
    end
  end
end
