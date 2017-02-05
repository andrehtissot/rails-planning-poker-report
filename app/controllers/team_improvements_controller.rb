class TeamImprovementsController < ApplicationController
  before_action :set_teams_by_experiment, only: [:index, :teams_comparison]

  def index
  end

  def show
    @experiment_number = params[:experiment]
    @team = Team.set_db(@experiment_number,2).find(params[:id])
    @team.experiment(@experiment_number).step(2)
    @requirements = Requirement.set_db(@experiment_number,2).for_experiment
  end

  def teams_comparison
  end
end
