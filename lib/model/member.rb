class Member
  def self.team(num, members)
    team = {}
    team_index = 0
    members.shuffle!
    members.each do |member|
      team["チーム#{team_index+1}"] = [] if team["チーム#{team_index+1}"].nil?
      team["チーム#{team_index+1}"].push(member)
      team_index = (team_index + 1)%num
    end
    team
  end

  def self.random(num, members)
    members.shuffle!
    members.take(num)
  end
end
