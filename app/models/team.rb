class Team < ActiveRecord::Base
  include FromExperiment
  include Calculator
  acts_as_paranoid
  has_many :team_participants
  has_many :participants, through: :team_participants
  validates :name, presence: true, uniqueness: true
  has_many :estimates

  def estimation_date_for_step step
    FromExperiment.set_all_db(self.experiment, step)
    estimative = Estimate.where(team_id: self.id).with_deleted.order('created_at DESC').first.created_at rescue nil
    estimative.nil? ? 'N/A' : estimative.strftime('%d/%m/%Y')
  end

  def participants_ids_with_deleted
    round_ids = []
    FromExperiment.set_all_db(self.experiment, self.step)
    (estimates = self.estimates(true)).each do |estimate|
      estimate.experiment(self.experiment).step(self.step)
      estimate.rounds.each {|round| round_ids << round.id }
    end
    participant_ids = []
    if !(estimates.empty?) && round_ids.empty?
      participant_ids = self.team_participants(true).collect {|tp| tp.participant(true).id }
    else
      RoundParticipant.where(round_id: round_ids).with_deleted.each do |round_participant|
        participant_ids << round_participant.participant(true).id
      end
    end
    participant_ids.uniq
  end

  def participants_with_deleted
    Participant.where(id: participants_ids_with_deleted)
  end

  def participantes_count step
    self.step(step)
    participants_ids_with_deleted.size
  end

  def participantes_count_only step
    self.step(step)
    ids_right_step = participants_ids_with_deleted
    self.step(step == 1 ? 2 : 1)
    ids_left_step = participants_ids_with_deleted
    ids_outer_right = ids_right_step.delete_if {|id| ids_left_step.include?(id)}
    ids_outer_right.size
  end

  def participants_names_with_deleted
    round_ids = []
    FromExperiment.set_all_db(self.experiment, self.step)
    rounds = []
    (estimates = self.estimates(true)).each do |estimate|
      estimate.experiment(self.experiment).step(self.step)
      estimate.rounds.each {|round| round_ids << round.id }
    end
    participant_names = []
    if !(estimates.empty?) && round_ids.empty?
      participant_names = self.team_participants(true).collect {|tp| tp.participant(true).name }
    else
      RoundParticipant.where(round_id: round_ids).with_deleted.each do |round_participant|
        participant_names << round_participant.participant(true).name
      end
    end
    participant_names.uniq.sort
  end

  def get_useful_estimates options = {}
    FromExperiment.set_all_db(self.experiment, self.step)
    if (options[:filter_by][:requirements_ids] rescue nil).nil?
      requirements_ids_to_exclude = Requirement.where(for_experiment: true).where('real_effort > 12').collect {|e| e.id}
      return self.estimates(true).where('requirement_id IS NOT NULL AND effort_estimate IS NOT NULL AND requirement_id NOT IN (?)',
        requirements_ids_to_exclude)
    else
      return self.estimates(true).where('requirement_id IS NOT NULL AND effort_estimate IS NOT NULL AND requirement_id IN (?)',
        options[:filter_by][:requirements_ids])
    end
  end

  def mean_effort_estimate
    self.class.return_mean(self.get_useful_estimates.collect {|e| e.effort_estimate })
  end

  def median_effort_estimate
    self.class.return_median(self.get_useful_estimates.collect {|e| e.effort_estimate })
  end

  def mean_real_effort
    self.class.return_mean(self.get_useful_estimates.collect {|e| e.requirement.real_effort })
  end

  def median_real_effort
    self.class.return_median(self.get_useful_estimates.collect {|e| e.requirement.real_effort })
  end

  def mean_effort_estimate_diff
    self.class.return_mean(self.get_useful_estimates.collect do |e|
      (e.effort_estimate / e.requirement.real_effort).abs
    end)
  end

  def median_effort_estimate_diff
    self.class.return_median(self.get_useful_estimates.collect do |e|
      (e.effort_estimate / e.requirement.real_effort).abs
    end)
  end

  [:ar, :mse, :bre, :ibre, :mer, :mre].each do |formula|
    define_method("m#{formula}") do |*args|
      options = args.first
      p self.get_useful_estimates(options)
      self.class.return_mean(self.get_useful_estimates(options).collect {|e| e.requirement.send(formula,e.effort_estimate) })
    end
    define_method("md#{formula}") do |*args|
      options = args.first
      self.class.return_median(self.get_useful_estimates(options).collect {|e| e.requirement.send(formula,e.effort_estimate) })
    end
  end

  def pred25_mre
    self.class.return_pred25(self.get_useful_estimates.collect {|e| e.requirement.mre(e.effort_estimate) })
  end

  #Needs revising!
  def mmse_diff_between_steps requirements_ids, options = {}
    cached_mse = {}
    [1,2].each do |step|
      cached_mse[step] = {}
      FromExperiment.set_all_db(self.class.experiment, step)
      estimates = self.step(step).get_useful_estimates
      unless requirements_ids.nil?
        estimates = estimates.select {|estimate| requirements_ids.include?(estimate.requirement_id)}
      end
      estimates.each do |estimate|
        requirement = estimate.step(step).requirement.step(step)
        cached_mse[step][requirement.id] = requirement.mse estimate.effort_estimate.round(4)
      end
    end
    cached_mse_diff = []
    cached_mse[1].each do |requirement_id,mse_step_1|
      cached_mse_diff << self.class.return_relative_diff(mse_step_1.round(4), cached_mse[2][requirement_id].round(4)).round(4)
    end
    cached_mse_diff.reject! {|mse_diff| mse_diff == Float::INFINITY}
    self.class.return_mean(cached_mse_diff)
  end

  def count_improvement(options = {})
    found_mse_1 = {}
    FromExperiment.set_all_db(self.experiment, 1)
    self.step(1)
    self.get_useful_estimates.collect {|e| found_mse_1[e.requirement.id] = e.requirement.mse(e.effort_estimate)}

    found_mse_2 = {}
    FromExperiment.set_all_db(self.experiment, 2)
    self.step(2)
    self.get_useful_estimates.collect {|e| found_mse_2[e.requirement.id] = e.requirement.mse(e.effort_estimate)}

    positive_count = 0.0
    neutral_count = 0.0
    negative_count = 0.0
    cost_positive_count = 0.0
    cost_negative_count = 0.0
    requirement_ids = []
    Requirement.for_experiment.select(:id).each do |requirement|
      next if found_mse_1[requirement.id].nil?
      next if found_mse_2[requirement.id].nil?
      neutral_count+=1.0 if found_mse_1[requirement.id] == found_mse_2[requirement.id]
      positive_count+=1.0 if found_mse_1[requirement.id] > found_mse_2[requirement.id]
      negative_count+=1.0 if found_mse_1[requirement.id] < found_mse_2[requirement.id]
      if(options[:add_requirement_ids])
        requirement_ids << requirement.id
      end
      if(options[:add_cost])
        relative_diff = self.relative_minutes_diff(requirement_id: requirement.id) rescue 0.0
        cost_positive_count+=1.0 if relative_diff < 0.0
        cost_negative_count+=1.0 if relative_diff > 0.0
      end
    end
    sum = 1.0 if (count = sum = positive_count + neutral_count + negative_count) == 0.0
    result = {positive_absolute: positive_count.to_i, neutral_absolute: neutral_count.to_i, negative_absolute: negative_count.to_i,
      positive_relative: positive_count/sum, neutral_relative: neutral_count/sum, count: count.to_i,
      negative_relative: negative_count/sum}
    if(options[:add_cost])
      cost_neutral_count = count - cost_negative_count - cost_positive_count
      result.delete(:count)
      result = {count: count, accuracy: result, cost: {positive_absolute: cost_positive_count.to_i, neutral_absolute: cost_neutral_count.to_i,
        negative_absolute: cost_negative_count.to_i, positive_relative: cost_positive_count/sum, neutral_relative: cost_neutral_count/sum,
        negative_relative: cost_negative_count/sum}}
    end
    result[:requirement_ids] = requirement_ids if(options[:add_requirement_ids])
    result
  end

  def mean_real_effort_beetween_steps
    self.class.return_mean(real_effort_beetween_steps_array)
  end

  def median_real_effort_beetween_steps
    self.class.return_median(real_effort_beetween_steps_array)
  end

  def mean_real_effort_beetween_steps_relative_to_real
    self.class.return_mean(real_effort_beetween_steps_relative_to_real_array)
  end

  def median_real_effort_beetween_steps_relative_to_real
    self.class.return_median(real_effort_beetween_steps_relative_to_real_array)
  end

  def requirements_answered_in_both_steps
    requirements_ids_step_1 = self.requirements_ids_answered 1
    requirements_ids_step_2 = self.requirements_ids_answered 2
    requirements_ids_step_1.select {|requirements_ids| requirements_ids_step_2.include?(requirements_ids)}
  end

  def requirements_ids_answered step
    old_step = self.step
    self.step step
    requirements_ids = self.get_useful_estimates.collect {|estimate| estimate.requirement_id}
    self.step old_step
    requirements_ids
  end

  private
  def real_effort_beetween_steps_array
    found_real_efforts = {}
    found_estimates_1 = {}
    FromExperiment.set_all_db(Requirement.experiment, 1)
    self.experiment(Requirement.experiment).step(1)
    self.get_useful_estimates.each do |e|
      found_estimates_1[e.requirement.id] = e.effort_estimate
      found_real_efforts[e.requirement.id] = e.requirement.real_effort
    end

    found_estimates_2 = {}
    FromExperiment.set_all_db(Requirement.experiment, 2)
    self.experiment(Requirement.experiment).step(2)
    self.get_useful_estimates.each {|e| found_estimates_2[e.requirement.id] = e.effort_estimate }

    found_keys = found_estimates_1.keys.concat(found_estimates_2.keys).uniq
    values = found_keys.collect do |k|
      begin
        step_one_estimate = found_estimates_1[k]
        step_two_estimate = found_estimates_2[k]
        real_effort = found_real_efforts[k]
        relative_estimate_one = step_one_estimate/real_effort
        relative_estimate_two = step_two_estimate/real_effort
        result = (([relative_estimate_one, relative_estimate_two].max / [relative_estimate_one, relative_estimate_two].min)-1)
        result *= (((real_effort - step_one_estimate).abs > (real_effort - step_two_estimate).abs) ? 100 : -100) if result != 0.0
        result
      rescue
        nil
      end
    end
    values.delete_if {|value| value.nil?}
    values
  end

  def real_effort_beetween_steps_relative_to_real_array
    found_real_efforts = {}
    found_estimates_1 = {}
    FromExperiment.set_all_db(Requirement.experiment, 1)
    self.experiment(Requirement.experiment).step(1)
    self.get_useful_estimates.each do |e|
      found_estimates_1[e.requirement.id] = e.effort_estimate
      found_real_efforts[e.requirement.id] = e.requirement.real_effort
    end

    found_estimates_2 = {}
    FromExperiment.set_all_db(Requirement.experiment, 2)
    self.experiment(Requirement.experiment).step(2)
    self.get_useful_estimates.each {|e| found_estimates_2[e.requirement.id] = e.effort_estimate }

    found_keys = found_estimates_1.keys.concat(found_estimates_2.keys).uniq
    values = found_keys.collect do |k|
      begin
        step_one_estimate = found_estimates_1[k]
        step_two_estimate = found_estimates_2[k]
        real_effort = found_real_efforts[k]
        relative_estimate_one = step_one_estimate/real_effort
        relative_estimate_two = step_two_estimate/real_effort
        result = (relative_estimate_one-relative_estimate_two).abs
        result *= (((real_effort - step_one_estimate).abs > (real_effort - step_two_estimate).abs) ? 100 : -100) if result != 0.0
        result
      rescue
        nil
      end
    end
    values.delete_if {|value| value.nil?}
    values
  end

  public
  def minutes_spent(contiditions)
    if contiditions[:requirement_id]
      return AccessLog.minutes_spent_in_requirement(self.id,contiditions[:requirement_id]) if ['three','four',3,4].include?(self.experiment)
      return RecoveredAccessLog.minutes_spent_in_requirement(self.class.human_to_number(self.experiment),self.step,self.id,contiditions[:requirement_id])
    end
    nil
  end

  def mean_minutes_spent(contiditions)
    if contiditions[:requirements]
      requirement_ids = contiditions[:requirements].collect {|requirement| requirement.id}
      return self.mean_minutes_spent requirement_ids: requirement_ids
    end
    if contiditions[:requirement_ids]
      minutes_per_requirement = []
      contiditions[:requirement_ids].each do |requirement_id|
        minutes = self.minutes_spent(requirement_id: requirement_id)
        minutes_per_requirement << (minutes > 0.0 ? minutes : nil)
      end
      return self.class.return_mean(minutes_per_requirement.compact)
    end
    nil
  end

  def median_minutes_spent(contiditions)
    if contiditions[:requirements]
      minutes_per_requirement = []
      contiditions[:requirements].each do |requirement|
        minutes = self.minutes_spent(requirement_id: requirement.id)
        minutes_per_requirement << (minutes > 0.0 ? minutes : nil)
      end
      return self.class.return_median(minutes_per_requirement.compact)
    end
    nil
  end

  def relative_minutes_diff(contiditions)
    old_step = self.step
    self.step(1)
    FromExperiment.set_all_db(Requirement.experiment, 1)
    minutes_spent_1 = self.minutes_spent(contiditions)
    self.step(2)
    FromExperiment.set_all_db(Requirement.experiment, 2)
    minutes_spent_2 = self.minutes_spent(contiditions)
    self.step(old_step)
    FromExperiment.set_all_db(Requirement.experiment, old_step)
    relative_diff(minutes_spent_1,minutes_spent_2)
  end

  def relative_diff(minutes_spent_1,minutes_spent_2)
    raise nil if [minutes_spent_1,minutes_spent_2].min == 0.0
    self.class.return_relative_diff(minutes_spent_1, minutes_spent_2)
  end

  def relative_diff_verbose(minutes_spent_1,minutes_spent_2)
    self.relative_diff(minutes_spent_1,minutes_spent_2).round(2)
  end
end
