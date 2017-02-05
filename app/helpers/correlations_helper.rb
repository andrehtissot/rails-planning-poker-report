module CorrelationsHelper
  def gsl_pearson(x,y)
    require 'gsl'
    GSL::Stats::correlation(GSL::Vector.alloc(x),GSL::Vector.alloc(y))
  end
end
