module Calculator
  extend ActiveSupport::Concern

  module ClassMethods
    def self.return_mean values_array
      values_array.reduce(:+).try(:to_f).try(:/,values_array.size)
    end

    def self.return_median values_array
      return nil if values_array.empty?
      sorted = values_array.sort
      len = sorted.length
      (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
    end

    def self.return_pred25 values_array
      (100/(values_array.length)) * (values_array.collect {|value| value.to_f <= 0.25 ? 1 : 0}).sum
    end

    def self.return_relative_diff_verbose relative_estimate_one, relative_estimate_two
      (self.return_relative_diff(relative_estimate_one, relative_estimate_two)*100).round(2)
    end

    def self.return_relative_diff relative_estimate_one, relative_estimate_two
      (relative_estimate_one > relative_estimate_two) ?
        (-1 + (([relative_estimate_one, relative_estimate_two].min / [relative_estimate_one, relative_estimate_two].max))) :
        ((([relative_estimate_one, relative_estimate_two].max / [relative_estimate_one, relative_estimate_two].min)) - 1)
    end
  end
end