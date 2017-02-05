class RemoveAndreCaioTeam < ActiveRecord::Migration
  def change
  	FromExperiment.set_all_db(4, 1)
    Team.find(7).delete
  end
end
