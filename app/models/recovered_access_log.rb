class RecoveredAccessLog < ActiveRecord::Base
  establish_connection 'pprecover_from_log_file'

  def self.minutes_spent_in_requirement(experiment_number, experiment_step, team_id, requirement_id)
    seconds = 0
    last_access = nil
    self.where("experiment_number = #{experiment_number} AND experiment_step = #{experiment_step} AND team_id = #{team_id} AND response_code = 200 AND route != '/browser_logs/create' AND route NOT LIKE '/requirements%'").order('access_time').each do |access_log|
      if last_access
        seconds += access_log.access_time - last_access
        last_access = nil
      end
      if access_log.route.start_with?('/estimates?requirement=')
        found_requirement_id = access_log.route.gsub('/estimates?requirement=','')
        next if found_requirement_id != requirement_id.to_s
        last_access = access_log.access_time
      end
    end
    seconds / 60.0
  end
end
