module RedmineStatusAlias
  module QueryPatch
    def issue_statuses_values
      statuses =
        if project
          project.rolled_up_statuses
        else
          IssueStatus.all.sorted
        end

      project_context = project if project && RedmineStatusAlias::Settings.enabled_for_project?(project)
      allow_global = project.blank?

      statuses.to_a.map do |status|
        name =
          RedmineStatusAlias::Settings.visible_name_for(
            status,
            project: project_context,
            allow_global: allow_global
          ) || RedmineStatusAlias::Settings.raw_status_name(status)

        [name, status.id.to_s]
      end
    end
  end
end
