class Requirement < ActiveRecord::Base
  include FromExperiment
  include Calculator
  acts_as_paranoid
  has_many :estimates

  def self.for_experiment
    self.where(for_experiment: true).where('real_effort < 12')
  end

  def team_effort_estimate team_id
    FromExperiment.set_all_db(self.experiment, step)
    self.step(step).estimates(true).where(team_id: team_id).last.effort_estimate rescue nil
  end

  #def self.euclidean_distance(a, b)
  #  sq = a.zip(b).map{|a,b| (a - b) ** 2}
  #  Math.sqrt(sq.inject(0) {|s,c| s + c})
  #end

  def team_effort_estimate_diff(team_id)
    (self.team_effort_estimate(team_id) / self.real_effort).abs
  end

  def ar estimate
    (self.real_effort - estimate).abs
  end

  def mse estimate
    (self.real_effort - estimate)**2
  end

  def bre estimate
    (self.real_effort - estimate).abs / [real_effort, estimate].min
  end

  def ibre estimate
    (self.real_effort - estimate).abs / [real_effort, estimate].max
  end

  def mer estimate
    (self.real_effort - estimate).abs / real_effort
  end

  def mre estimate
    (self.real_effort - estimate).abs / estimate
  end

  def real_effort_beetween_steps step_one_estimate, step_two_estimate
    relative_estimate_one = step_one_estimate/real_effort
    relative_estimate_two = step_two_estimate/real_effort
    result = (([relative_estimate_one, relative_estimate_two].max / [relative_estimate_one, relative_estimate_two].min)-1)
    result *= (((real_effort - step_one_estimate).abs > (real_effort - step_two_estimate).abs) ? 100 : -100) if result != 0.0
    result
  end

  def real_effort_beetween_steps_relative_to_real step_one_estimate, step_two_estimate
    relative_estimate_one = step_one_estimate/real_effort
    relative_estimate_two = step_two_estimate/real_effort
    result = (relative_estimate_one-relative_estimate_two).abs
    result *= (((real_effort - step_one_estimate).abs > (real_effort - step_two_estimate).abs) ? 100 : -100) if result != 0.0
    result
  end

  def ar_relative_diff_verbose step_one_estimate, step_two_estimate
    self.class.return_relative_diff_verbose(self.ar(step_one_estimate), self.ar(step_two_estimate))
  end

  def mse_relative_diff_verbose step_one_estimate, step_two_estimate
    self.class.return_relative_diff_verbose(self.mse(step_one_estimate), self.mse(step_two_estimate))
  end

  def bre_relative_diff_verbose step_one_estimate, step_two_estimate
    self.class.return_relative_diff_verbose(self.bre(step_one_estimate), self.bre(step_two_estimate))
  end

  def ibre_relative_diff_verbose step_one_estimate, step_two_estimate
    self.class.return_relative_diff_verbose(self.ibre(step_one_estimate), self.ibre(step_two_estimate))
  end

  def mer_relative_diff_verbose step_one_estimate, step_two_estimate
    self.class.return_relative_diff_verbose(self.mer(step_one_estimate), self.mer(step_two_estimate))
  end

  def mre_relative_diff_verbose step_one_estimate, step_two_estimate
    self.class.return_relative_diff_verbose(self.mre(step_one_estimate), self.mre(step_two_estimate))
  end

  def teams_mean_effort_estimate teams_for_experiment, step
    effort_estimates = []
    teams_for_experiment.each_with_index do |teams, experiment|
      FromExperiment.set_all_db(experiment+1, step)
      effort_estimates += Estimate.where(requirement: self, team: (teams.collect {|team| team.id})).all.collect {|estimate| estimate.effort_estimate}
    end
    self.class.return_mean(effort_estimates)
  end

  def get_effort_estimates teams_for_experiment, step
    effort_estimates = []
    teams_for_experiment.each_with_index do |teams, experiment|
      FromExperiment.set_all_db(experiment+1, step)
      effort_estimates += Estimate.where(requirement: self, team: (teams.collect {|team| team.id})).all.collect {|estimate| estimate.effort_estimate}
      effort_estimates.reject! {|effort_estimate| effort_estimate.nil? || effort_estimate <= 0.0}
    end
    effort_estimates
  end

  def get_effort_estimates_by_experiment_and_team teams_for_experiment, step
    effort_estimates = {}
    teams_for_experiment.each_with_index do |teams, experiment|
      effort_estimates[experiment] = {}
      FromExperiment.set_all_db(experiment+1, step)
      Estimate.where(requirement: self, team: (teams.collect {|team| team.id})).all.each do |estimate|
        unless estimate.effort_estimate.nil? || estimate.effort_estimate <= 0.0
          effort_estimates[experiment][estimate.team.id] = estimate.effort_estimate
        end
      end
    end
    effort_estimates
  end

  def mar effort_estimates
    self.class.return_mean(effort_estimates.collect {|effort_estimate| self.ar(effort_estimate) })
  end

  def mdar effort_estimates
    self.class.return_median(effort_estimates.collect {|effort_estimate| self.ar(effort_estimate) })
  end

  def mmse effort_estimates
    self.class.return_mean(effort_estimates.collect {|effort_estimate| self.mse(effort_estimate) })
  end

  def mdmse effort_estimates
    self.class.return_median(effort_estimates.collect {|effort_estimate| self.mse(effort_estimate) })
  end

  def mbre effort_estimates
    self.class.return_mean(effort_estimates.collect {|effort_estimate| self.bre(effort_estimate) })
  end

  def mdbre effort_estimates
    self.class.return_median(effort_estimates.collect {|effort_estimate| self.bre(effort_estimate) })
  end

  def mibre effort_estimates
    self.class.return_mean(effort_estimates.collect {|effort_estimate| self.ibre(effort_estimate) })
  end

  def mdibre effort_estimates
    self.class.return_median(effort_estimates.collect {|effort_estimate| self.ibre(effort_estimate) })
  end

  def mmer effort_estimates
    self.class.return_mean(effort_estimates.collect {|effort_estimate| self.mer(effort_estimate) })
  end

  def mdmer effort_estimates
    self.class.return_median(effort_estimates.collect {|effort_estimate| self.mer(effort_estimate) })
  end

  def mmre effort_estimates
    self.class.return_mean(effort_estimates.collect {|effort_estimate| self.mre(effort_estimate) })
  end

  def mdmre effort_estimates
    self.class.return_median(effort_estimates.collect {|effort_estimate| self.mre(effort_estimate) })
  end

  def pred25_mre effort_estimates
    self.class.return_pred25(effort_estimates.collect {|effort_estimate| self.mre(effort_estimate) })
  end

  def get_count_results teams_by_experiment
    effort_estimates_step_1 = self.get_effort_estimates_by_experiment_and_team teams_by_experiment, 1
    effort_estimates_step_2 = self.get_effort_estimates_by_experiment_and_team teams_by_experiment, 2
    results = {positive_absolute: 0, neutral_absolute: 0, negative_absolute: 0,
      positive_relative: 0.0, neutral_relative: 0.0, negative_relative: 0.0}

    teams_count = 0
    effort_estimates_step_1.each do |experiment, effort_by_team_id|
      effort_by_team_id.each do |team_id, estimate|
        next if effort_estimates_step_2[experiment][team_id].nil?
        teams_count += 1
        mse_1 = self.mse(estimate)
        mse_2 = self.mse(effort_estimates_step_2[experiment][team_id])
        if(mse_1 == mse_2)
          results[:neutral_absolute] += 1
        elsif(mse_1 > mse_2)
          results[:positive_absolute] += 1
        else
          results[:negative_absolute] += 1
        end
      end
    end
    results[:positive_relative] = results[:positive_absolute].to_f / teams_count
    results[:neutral_relative] = results[:neutral_absolute].to_f / teams_count
    results[:negative_relative] = results[:negative_absolute].to_f / teams_count
    results
  end
end
