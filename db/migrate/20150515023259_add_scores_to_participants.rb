class AddScoresToParticipants < ActiveRecord::Migration
  def change
	1.upto(4).each do |experiment|
		[1,2].each do |step|
  			add_column "ppexperiment_#{Participant.number_to_human(experiment)}_step_#{Participant.number_to_human(step)}.participants", :mean_if_score, :float
  		end
  	end
  end
end
