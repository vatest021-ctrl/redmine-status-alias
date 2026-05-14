module RedmineStatusAlias
  module ReportsControllerPatch
    def find_issue_statuses
      super
      RedmineStatusAlias::Settings.assign_project_to_statuses(@statuses, @project)
    end

    private :find_issue_statuses
  end
end
