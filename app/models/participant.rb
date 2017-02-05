class Participant < ActiveRecord::Base
  include FromExperiment
  acts_as_paranoid
  has_many :competences
  has_many :round_participants
  #has_many :rounds, through: :round_participants
  #has_many :team_participants
  #has_many :teams, through: :team_participants
  validates :name, presence: true
  validates :sex, presence: true
  validates :birthday, timeliness: { before: lambda{Date.current}, type: :date }

  def sex_verbose
    case sex
      when 1 then 'Masculino'
      when 2 then 'Feminino'
      else ''
    end
  end

  def birthday_verbose
  	self.birthday.strftime("%d/%m/%Y") rescue ''
  end

  def count_improvement
    requirement_by_requirement_hashkey_by_step = {}
    round_participants_by_requirement_hashkey_by_step = {}
    [1,2].each do |step|
      FromExperiment.set_all_db(Participant.experiment, step)
      requirement_by_requirement_hashkey_by_step[step] = {}
      round_participants_by_requirement_hashkey_by_step[step] = {}
      round_participants = self.round_participants(true).where("effort_estimate > 0").all.to_a
      round_participants.each do |round_participant|
        requirement = round_participant.round.estimate.requirement
        next if(requirement_by_requirement_hashkey_by_step[step].has_key?(requirement.hashkey) &&
          round_participants_by_requirement_hashkey_by_step[step][requirement.hashkey].created_at <
          round_participant.created_at)
        requirement_by_requirement_hashkey_by_step[step][requirement.hashkey] = requirement
        round_participants_by_requirement_hashkey_by_step[step][requirement.hashkey] = round_participant
      end
    end
    hashkeys_to_compare = round_participants_by_requirement_hashkey_by_step[1].keys &
      round_participants_by_requirement_hashkey_by_step[2].keys
    positive_count = 0.0
    neutral_count = 0.0
    negative_count = 0.0
    hashkeys_to_compare.each do |hashkey|
      effort_estimate_1 = round_participants_by_requirement_hashkey_by_step[1][hashkey].effort_estimate
      effort_estimate_2 = round_participants_by_requirement_hashkey_by_step[2][hashkey].effort_estimate
      found_mse_1 = requirement_by_requirement_hashkey_by_step[1][hashkey].mse(effort_estimate_1)
      found_mse_2 = requirement_by_requirement_hashkey_by_step[2][hashkey].mse(effort_estimate_2)
      neutral_count+=1.0 if found_mse_1 == found_mse_2
      positive_count+=1.0 if found_mse_1 > found_mse_2
      negative_count+=1.0 if found_mse_1 < found_mse_2
    end
    sum = 1.0 if (count = sum = positive_count + neutral_count + negative_count) == 0.0
    {positive_absolute: positive_count.to_i, neutral_absolute: neutral_count.to_i, negative_absolute: negative_count.to_i,
        positive_relative: positive_count/sum, neutral_relative: neutral_count/sum, count: count.to_i,
        negative_relative: negative_count/sum}
  end
end
