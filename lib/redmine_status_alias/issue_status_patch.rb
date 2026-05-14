module RedmineStatusAlias
  module IssueStatusPatch
    attr_accessor :redmine_status_alias_project

    def name
      project = redmine_status_alias_project || RedmineStatusAlias::Context.project
      RedmineStatusAlias::Settings.visible_name_for(self, project: project) ||
        RedmineStatusAlias::Settings.raw_status_name(self)
    end
  end
end
