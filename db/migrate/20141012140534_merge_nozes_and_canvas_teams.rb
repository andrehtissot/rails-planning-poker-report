class MergeNozesAndCanvasTeams < ActiveRecord::Migration
  def change
    FromExperiment.set_all_db(1, 1)
    Team.where(id: 4).update_all(id: 6)
    TeamParticipant.where(team_id: 4).update_all(team_id: 6)
    Estimate.where(team_id: 4).update_all(team_id: 6)
  end
end
