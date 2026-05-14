module RedmineStatusAlias
  module Settings
    DEFAULTS = {
      "client_role_ids" => [],
      "internal_role_ids" => [],
      "status_aliases" => {},
    }.freeze

    module_function

    def settings
      raw = Setting.plugin_redmine_status_alias
      DEFAULTS.merge(raw.is_a?(Hash) ? raw : {})
    end

    def enabled_for_project?(project)
      return false if project.blank?

      project.module_enabled?(:status_alias)
    end

    def client_role_ids
      Array(settings["client_role_ids"]).reject(&:blank?).map(&:to_i)
    end

    def internal_role_ids
      Array(settings["internal_role_ids"]).reject(&:blank?).map(&:to_i)
    end

    def status_aliases
      aliases = settings["status_aliases"]
      aliases.is_a?(Hash) ? aliases : {}
    end

    def alias_status_id_for(status_id)
      value = status_aliases[status_id.to_s]
      value.present? ? value.to_i : nil
    end

    def visible_name_for(status, user: User.current, project: nil, allow_global: false)
      return if status.blank?
      return unless alias_context_applies?(user, project: project, allow_global: allow_global)

      alias_name_for(status)
    rescue StandardError => e
      Rails.logger.warn("[redmine_status_alias] Failed to resolve status alias: #{e.class}: #{e.message}") if defined?(Rails)
      nil
    end

    def alias_name_for(status)
      alias_id = alias_status_id_for(status.id)
      return if alias_id.blank? || alias_id == status.id

      alias_status = IssueStatus.find_by(id: alias_id)
      return unless alias_status

      raw_status_name(alias_status)
    end

    def visible_name_for_status_id(status_id, user: User.current, project: nil, allow_global: false)
      status = IssueStatus.find_by(id: status_id)
      return if status.blank?

      visible_name_for(status, user: user, project: project, allow_global: allow_global) || raw_status_name(status)
    end

    def assign_project_to_statuses(statuses, project)
      Array(statuses).each do |status|
        status.redmine_status_alias_project = project if status.respond_to?(:redmine_status_alias_project=)
      end
      statuses
    end

    def raw_status_name(status)
      if status.respond_to?(:read_attribute)
        status.read_attribute(:name)
      else
        status.name
      end
    end

    def alias_context_applies?(user, project: nil, allow_global: false)
      if project.present?
        enabled_for_project?(project) && applies_to_user?(user, project: project)
      elsif allow_global
        applies_to_user_in_any_enabled_project?(user)
      else
        false
      end
    end

    def applies_to_user?(user, project:)
      return false if user.blank?
      return false if user.respond_to?(:admin?) && user.admin?

      selected_role_ids = client_role_ids
      return false if selected_role_ids.empty?

      role_ids = role_ids_for(user, project: project)
      return false if (role_ids & internal_role_ids).any?

      (role_ids & selected_role_ids).any?
    end

    def applies_to_user_in_any_enabled_project?(user)
      return false if user.blank?
      return false if user.respond_to?(:admin?) && user.admin?

      selected_role_ids = client_role_ids
      return false if selected_role_ids.empty?

      enabled_memberships = memberships_for(user).select { |membership| enabled_for_project?(membership.project) }
      return false if enabled_memberships.any? { |membership| (membership_role_ids(membership) & internal_role_ids).any? }

      enabled_memberships.any? { |membership| (membership_role_ids(membership) & selected_role_ids).any? }
    end

    def role_ids_for(user, project: nil)
      ids = []

      if user.respond_to?(:anonymous?) && user.anonymous? && defined?(Role)
        anonymous_role = Role.respond_to?(:anonymous) ? Role.anonymous : nil
        ids << anonymous_role.id if anonymous_role
      end

      if user.respond_to?(:memberships)
        memberships = memberships_for(user)
        memberships = memberships.select { |membership| membership.project_id == project.id } if project

        ids.concat(memberships.flat_map { |membership| membership_role_ids(membership) })
      end

      ids.compact.uniq
    end

    def memberships_for(user)
      user.respond_to?(:memberships) ? user.memberships.includes(:roles, :project).to_a : []
    rescue StandardError
      user.respond_to?(:memberships) ? user.memberships.to_a : []
    end

    def membership_role_ids(membership)
      membership.respond_to?(:roles) ? membership.roles.map(&:id) : []
    end
  end
end
