class AccessLog < ActiveRecord::Base
  include FromExperiment

  def self.session_id_from_team_id(team_id)
    session_ids = self.where("header_json NOT LIKE '%\"REMOTE_ADDR\":\"127.0.0.1\"%' AND controller = 'estimates' AND action = 'update'").group('session_json').map do |access_log|
      session_json = JSON.parse(access_log.session_json)
      session_json['team_id'] == team_id ? session_json['session_id'] : nil
    end
    session_ids.compact!.uniq!
    return session_ids.first if session_ids.count == 1
    raise "Encontrado mais de um session_id: #{session_ids.to_s}"
  end

  def self.minutes_spent_in_requirement(team_id, requirement_id)
    session_id = self.session_id_from_team_id(team_id)
    seconds = 0
    last_access = nil
    self.where("controller NOT IN ('browser_logs','requirements') AND action NOT IN ('create_round','update') AND session_json LIKE '%#{session_id}%'").order('created_at').each do |access_log|
      params = JSON.parse(access_log.params)
      if last_access
        seconds += access_log.created_at - last_access
        last_access = nil
      end
      next if params['requirement'] != requirement_id.to_s
      last_access = access_log.created_at
    end
    seconds / 60.0
  end
end
