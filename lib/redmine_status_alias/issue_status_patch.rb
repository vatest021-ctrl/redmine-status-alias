module RedmineStatusAlias
  module IssueStatusPatch
    attr_accessor :redmine_status_alias_project

    def name
      RedmineStatusAlias::Settings.visible_name_for(self, project: redmine_status_alias_project) ||
        RedmineStatusAlias::Settings.raw_status_name(self)
    end
  end
end
