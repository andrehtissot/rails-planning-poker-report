class RequirementImprovementsController < ApplicationController
	before_action :set_teams_by_experiment
  before_action :set_requirements

  def index
  end

  def teams_that_answered
  end

  def results_by_requirement
  end

  def count_by_requirement
  end

  private
  def set_requirements
    FromExperiment.set_all_db(1,2)
    @requirements = Requirement.for_experiment
  end
end
