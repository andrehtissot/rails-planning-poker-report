class RemoveCanvasTeam < ActiveRecord::Migration
  def change
    FromExperiment.set_all_db(1, 2)
    Team.find(4).delete
  end
end
