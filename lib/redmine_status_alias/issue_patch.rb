module RedmineStatusAlias
  module IssuePatch
    def status(*args, &block)
      issue_status = super
      issue_status.redmine_status_alias_project = project if issue_status.respond_to?(:redmine_status_alias_project=)
      issue_status
    end

    def new_statuses_allowed_to(user = User.current, include_default = false)
      statuses = super
      RedmineStatusAlias::Settings.assign_project_to_statuses(statuses, project)
    end
  end
end
