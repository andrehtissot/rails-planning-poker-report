class ChangeCanvasTeamName < ActiveRecord::Migration
  def change
    FromExperiment.set_all_db(1, 2)
    new_name = Team.find(6).name
    FromExperiment.set_all_db(1, 1)
    (team = Team.find(6)).name = new_name
    team.save!
  end
end
