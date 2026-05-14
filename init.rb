$LOAD_PATH.unshift File.expand_path("lib", __dir__)

require "redmine_status_alias"

Rails.configuration.to_prepare do
  begin
    require_dependency "issue"
    require_dependency "issue_status"

    if defined?(Issue) && !Issue.ancestors.include?(RedmineStatusAlias::IssuePatch)
      Issue.prepend RedmineStatusAlias::IssuePatch
    end

    if defined?(IssueStatus) && !IssueStatus.ancestors.include?(RedmineStatusAlias::IssueStatusPatch)
      IssueStatus.prepend RedmineStatusAlias::IssueStatusPatch
    end
  rescue StandardError => e
    warn "[redmine_status_alias] Failed to include patches: #{e.class}: #{e.message}"
    warn Array(e.backtrace).first(10).join("\n")
  end
end

Redmine::Plugin.register :redmine_status_alias do
  name "Redmine Status Alias"
  author "Valeriy Popov"
  description "Displays configurable customer-facing aliases for Redmine issue statuses."
  version "0.1.0"
  url "https://github.com/vatest021-ctrl/redmine-status-alias"
  author_url "https://github.com/vatest021-ctrl"
  requires_redmine version_or_higher: "6.0.0"

  project_module :status_alias do
    permission :view_status_aliases, {}, require: :member
  end

  settings default: RedmineStatusAlias::Settings::DEFAULTS,
           partial: "settings/redmine_status_alias_settings"
end
