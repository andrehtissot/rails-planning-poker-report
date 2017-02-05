class CompetencesController < ApplicationController
  def index
    @experiments = params[:experiment].nil? ? 1.upto(4) : [params[:experiment].to_i]
    @competences_by_participant_and_experiment = {}
  	@experiments.each do |experiment|
      FromExperiment.set_all_db(experiment, 1)
      @competences_by_experiment_and_participant[experiment] = {}
      Participant.all.each do |participant|
        @competences_by_experiment_and_participant[experiment][participant.id] = participant.competences.all
      end
      FromExperiment.set_all_db(experiment, 2)
      Participant.all.each do |participant|
        @competences_by_experiment_and_participant[experiment][participant.id] = participant.competences.all
      end
  	end
  end
end
