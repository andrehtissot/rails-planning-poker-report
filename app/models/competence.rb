class Competence < ActiveRecord::Base
  include FromExperiment
  acts_as_paranoid
  belongs_to :participant

  def level_verbose
    case level
      when 1 then 'Básico'
      when 2 then 'Intermediário'
      when 3 then 'Avançado'
      else ''
    end
  end
end
