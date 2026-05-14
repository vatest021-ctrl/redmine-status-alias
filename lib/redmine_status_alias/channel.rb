module RedmineStatusAlias
  module Channel
    module_function

    def with_recipient(recipient = nil, issue: nil, project: nil, force_alias: false)
      Context.with(
        user: recipient,
        project: project || issue_project(issue),
        force_alias: force_alias
      ) do
        yield
      end
    end

    def with_client_display(issue: nil, project: nil)
      with_recipient(nil, issue: issue, project: project, force_alias: true) { yield }
    end

    def status_name(status_or_id, issue: nil, project: nil, recipient: nil, force_alias: false)
      project_context = project || issue_project(issue)
      status = status_record(status_or_id)
      return if status.blank?

      user = recipient || Context.user || User.current
      force =
        force_alias ||
        Context.force_alias? ||
        (
          project_context.present? &&
          recipient.blank? &&
          Context.user.blank? &&
          Settings.force_aliases_for_recipientless_channels? &&
          Settings.recipientless_user?(user)
        )

      Settings.visible_name_for(
        status,
        user: user,
        project: project_context,
        force_alias: force
      ) || Settings.raw_status_name(status)
    end

    def status_change_text(old_status_id, new_status_or_id, issue: nil, project: nil, recipient: nil, force_alias: false)
      [
        status_name(old_status_id, issue: issue, project: project, recipient: recipient, force_alias: force_alias),
        status_name(new_status_or_id, issue: issue, project: project, recipient: recipient, force_alias: force_alias),
      ].compact.join(" -> ")
    end

    def issue_project(issue)
      issue.project if issue.respond_to?(:project)
    end

    def status_record(status_or_id)
      return status_or_id if status_or_id.respond_to?(:id) && status_or_id.respond_to?(:name)
      return if status_or_id.blank?

      IssueStatus.find_by(id: status_or_id)
    end
  end
end
