module RequirementImprovementsHelper
	def relative_diff object, method, param_for_step_1, param_for_step_2
		relative_estimate_one = object.send(method, param_for_step_1).to_f
		relative_estimate_two = object.send(method, param_for_step_2).to_f
		raise 'Infinity' if relative_estimate_one == 0 && relative_estimate_two > 0.001
		(relative_estimate_one > relative_estimate_two ?
			([relative_estimate_one,relative_estimate_two].min / [relative_estimate_one,relative_estimate_two].max) - 1 :
			([relative_estimate_one,relative_estimate_two].max / [relative_estimate_one,relative_estimate_two].min) - 1)
	end

	def relative_diff_verbose object, method, param_for_step_1, param_for_step_2
		(relative_diff(object, method, param_for_step_1, param_for_step_2) * 100).round(2) rescue 'N/A'
	end
end
