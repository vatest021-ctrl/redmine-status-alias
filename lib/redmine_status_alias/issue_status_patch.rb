module RedmineStatusAlias
  module IssueStatusPatch
    attr_accessor :redmine_status_alias_project

    def name
      project = redmine_status_alias_project || RedmineStatusAlias::Context.project
      user = RedmineStatusAlias::Context.user || User.current
      force_alias =
        RedmineStatusAlias::Context.force_alias? ||
        (
          project.present? &&
          RedmineStatusAlias::Settings.force_aliases_for_recipientless_channels? &&
          RedmineStatusAlias::Settings.recipientless_user?(user)
        )

      RedmineStatusAlias::Settings.visible_name_for(
        self,
        user: user,
        project: project,
        force_alias: force_alias
      ) ||
        RedmineStatusAlias::Settings.raw_status_name(self)
    end
  end
end
