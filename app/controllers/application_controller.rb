class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private
  def set_teams_by_experiment
    @teams_by_experiment = []
    teams = []
    used_names = []
    [1,2,3,4].each do |experiment|
      [1,2].each do |step|
        FromExperiment.set_all_db(experiment, step)
        Team.set_db(experiment, step).all.each do |team|
          name = "#{team.name} (#{team.id})"
          next if used_names.include? name
          used_names << name
          team = team.experiment(Team.experiment).step(Team.step)
          teams << team
        end
      end
      @teams_by_experiment << (teams.sort { |a,b| a.name.downcase <=> b.name.downcase })
      teams = []
    end
  end
end
