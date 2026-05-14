module RedmineStatusAlias
  module IssueStatusPatch
    attr_accessor :redmine_status_alias_project

    def name
      project = redmine_status_alias_project || RedmineStatusAlias::Context.project
      user = RedmineStatusAlias::Context.user || User.current

      RedmineStatusAlias::Settings.visible_name_for(
        self,
        user: user,
        project: project
      ) ||
        RedmineStatusAlias::Settings.raw_status_name(self)
    end
  end
end
