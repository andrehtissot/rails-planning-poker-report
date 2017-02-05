module FromExperiment
  extend ActiveSupport::Concern

  module ClassMethods
    def number_to_human number
      case number
      when 1 then 'one'
      when '1' then 'one'
      when 2 then 'two'
      when '2' then 'two'
      when 3 then 'three'
      when '3' then 'three'
      when 4 then 'four'
      when '4' then 'four'
      else number
      end
    end

    def human_to_number verbose_number
      case verbose_number
      when 'one' then 1
      when 'two' then 2
      when 'three' then 3
      when 'four' then 4
      else verbose_number
      end
    end

    def set_db experiment, step
      @@experiment_number = number_to_human(experiment)
      @@step_number = number_to_human(step)
      @@connection_name = "ppexperiment_#{@@experiment_number}_step_#{@@step_number}".to_sym
      establish_connection(@@connection_name)
      self
    end

    def step
      @@step_number
    end

    def experiment
      @@experiment_number
    end
  end

  def step number = false
    return @step_number if number == false
    @step_number = number
    self
  end

  def experiment number = false
    return @experiment_number if number == false
    @experiment_number = number
    self
  end
end

def FromExperiment.set_all_db experiment, step
  Estimate.set_db(experiment,step)
  Participant.set_db(experiment,step)
  Requirement.set_db(experiment,step)
  Round.set_db(experiment,step)
  RoundParticipant.set_db(experiment,step)
  Team.set_db(experiment,step)
  TeamParticipant.set_db(experiment,step)
  Competence.set_db(experiment,step)
  AccessLog.set_db(experiment,step)
end
