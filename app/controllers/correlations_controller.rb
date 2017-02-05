class CorrelationsController < ApplicationController
  before_action :set_teams_by_experiment, only: [:by_experiment]

  def index
  end

  def by_experiment
    @correlation_keys = [
      ['MNPMC','Média das notas dos participantes em matérias de computação',[]],
      ['ARMDA','Aumento relativo (%) da média da diferença absoluta (MAR)',[]],
      ['AREQM','Aumento relativo (%) do erro quadrático médio (MSE)',[]],
      ['NEM','Número de estimativas que melhoram (%)',[]],
      ['NEP','Número de estimativas que pioraram (%)',[]],
      ['MNP','Média do número de participantes',[]],
      ['MMDAE1','Média da média da diferença absoluta (MAR) da etapa 1',[]],
      ['MMDAE2','Média da média da diferença absoluta (MAR) da etapa 2',[]]
    ]

    #@accepted_team_numbers = 1.upto(40)
    @accepted_team_numbers = [6,7,8,9,10,11,12,13,14,16,18,19,20,23]

    @experiments = params[:experiment].nil? ? 1.upto(4) : [params[:experiment].to_i]
    @cached = {}
    team_count = 0
    @experiments.each do |experiment|
      FromExperiment.set_all_db(experiment, 1)
      @cached[experiment] = {}
      @teams_by_experiment[experiment-1].each_with_index do |team,team_number|
        next unless @accepted_team_numbers.include?(team_count+=1)
        requirements_ids = team.requirements_answered_in_both_steps
        @cached[experiment][team_number] = {1 => {mar: nil, mmse: nil, mbre: nil,
          mibre: nil, mmer: nil, mmre: nil, mdar: nil, mdmse: nil,
          mdbre: nil, mdibre: nil, mdmer: nil, mdmre: nil, pred25_mre: nil,
          mean_if_score: nil, participant_names: nil, participants_count: nil, mean_minutes: nil},
          2 => nil, joined: nil}
        @cached[experiment][team_number][:joined] = (@cached[experiment][team_number][2] = @cached[experiment][team_number][1].clone).clone
        @cached[experiment][team_number][:joined][:improvements] = team.experiment(experiment).count_improvement(add_requirement_ids: true)
        [1,2].each do |step|
          FromExperiment.set_all_db(experiment, step)
          @cached[experiment][team_number][step][:participant_names] = (team.step(step).participants_names_with_deleted.each { |participant_name| }).join(', ')
          @cached[experiment][team_number][step][:participants_count] = team.step(step).participants_names_with_deleted.size
          @cached[experiment][team_number][step][:mean_if_score] = (Team.return_mean(team.step(step).participants_with_deleted.collect {|participant| participant.mean_if_score}) rescue nil)
          [:mar,:mmse,:mbre,:mibre,:mmer,:mmre,:mdar,:mdmse,:mdbre,:mdibre,:mdmer,:mdmre].each do |formula|
            @cached[experiment][team_number][step][formula] = ((team.step(step).send(formula,{filter_by: {requirements_ids: requirements_ids}})) rescue nil)
          end
          @cached[experiment][team_number][step][:pred25_mre] = ((team.step(step).pred25_mre) rescue nil)
          @cached[experiment][team_number][step][:mean_minutes] = team.step(step).mean_minutes_spent requirement_ids: @cached[experiment][team_number][:joined][:improvements][:requirement_ids]
        end
        [:mar,:mmse,:mbre,:mibre,:mmer,:mmre,:mdar,:mdmse,:mdbre,:mdibre,:mdmer,:mdmre,:pred25_mre,:mean_minutes].each do |formula|
          @cached[experiment][team_number][:joined][formula] = (Team.return_relative_diff_verbose(
            @cached[experiment][team_number][1][formula], @cached[experiment][team_number][2][formula]) rescue nil)
        end
      end

      @teams_by_experiment[experiment-1].size.times do |team_number|
        next if @cached[experiment][team_number].nil?
        next if @cached[experiment][team_number][:joined][:mar].nil?
        mean_if_score_1 = @cached[experiment][team_number][1][:mean_if_score].nil? ? @cached[experiment][team_number][2][:mean_if_score] : @cached[experiment][team_number][1][:mean_if_score]
        mean_if_score_2 = @cached[experiment][team_number][2][:mean_if_score].nil? ? @cached[experiment][team_number][1][:mean_if_score] : @cached[experiment][team_number][2][:mean_if_score]
        @correlation_keys[0].last << (mean_if_score_1 + mean_if_score_2)/2 rescue nil
        @correlation_keys[1].last << @cached[experiment][team_number][:joined][:mar]
        @correlation_keys[2].last << @cached[experiment][team_number][:joined][:mmse]
        @correlation_keys[3].last << @cached[experiment][team_number][:joined][:improvements][:positive_relative]
        @correlation_keys[4].last << @cached[experiment][team_number][:joined][:improvements][:negative_relative]
        participants_count_1 = @cached[experiment][team_number][1][:participants_count].nil? ? @cached[experiment][team_number][2][:participants_count] : @cached[experiment][team_number][1][:participants_count]
        participants_count_2 = @cached[experiment][team_number][2][:participants_count].nil? ? @cached[experiment][team_number][1][:participants_count] : @cached[experiment][team_number][2][:participants_count]
        @correlation_keys[5].last << (participants_count_1 + participants_count_2).to_f/2
        @correlation_keys[6].last << @cached[experiment][team_number][1][:mar]
        @correlation_keys[7].last << @cached[experiment][team_number][2][:mar]
      end
    end
  end
end
