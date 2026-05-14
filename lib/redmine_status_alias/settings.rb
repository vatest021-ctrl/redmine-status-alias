module RedmineStatusAlias
  module Settings
    DEFAULTS = {
      "client_role_ids" => [],
      "internal_role_ids" => [],
      "status_aliases" => {},
    }.freeze
    CLIENT_VIEW_PERMISSION = :view_status_aliases

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
      configured_role_ids("client_role_ids")
    end

    def internal_role_ids
      configured_role_ids("internal_role_ids")
    end

    def client_view_roles
      return [] unless defined?(Role)

      Role.order(:position).to_a.select { |role| role_has_permission?(role, CLIENT_VIEW_PERMISSION) }
    end

    def client_view_role_ids
      client_view_roles.map(&:id)
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

      roles = roles_for(user, project: project)
      role_ids = roles.map(&:id)
      return false if (role_ids & internal_role_ids).any?

      roles.any? { |role| selected_role_ids.include?(role.id) && role_has_permission?(role, CLIENT_VIEW_PERMISSION) }
    end

    def applies_to_user_in_any_enabled_project?(user)
      return false if user.blank?
      return false if user.respond_to?(:admin?) && user.admin?

      selected_role_ids = client_role_ids
      return false if selected_role_ids.empty?

      enabled_memberships = memberships_for(user).select { |membership| enabled_for_project?(membership.project) }
      return false if enabled_memberships.any? { |membership| (membership_role_ids(membership) & internal_role_ids).any? }

      enabled_memberships.any? do |membership|
        membership_roles(membership).any? do |role|
          selected_role_ids.include?(role.id) && role_has_permission?(role, CLIENT_VIEW_PERMISSION)
        end
      end
    end

    def role_ids_for(user, project: nil)
      roles_for(user, project: project).map(&:id)
    end

    def roles_for(user, project: nil)
      roles = []

      if user.respond_to?(:anonymous?) && user.anonymous? && defined?(Role)
        anonymous_role = Role.respond_to?(:anonymous) ? Role.anonymous : nil
        roles << anonymous_role if anonymous_role
      end

      if user.respond_to?(:memberships)
        memberships = memberships_for(user)
        memberships = memberships.select { |membership| membership.project_id == project.id } if project

        roles.concat(memberships.flat_map { |membership| membership_roles(membership) })
      end

      roles.compact.uniq { |role| role.id }
    end

    def memberships_for(user)
      user.respond_to?(:memberships) ? user.memberships.includes(:roles, :project).to_a : []
    rescue StandardError
      user.respond_to?(:memberships) ? user.memberships.to_a : []
    end

    def membership_role_ids(membership)
      membership_roles(membership).map(&:id)
    end

    def membership_roles(membership)
      membership.respond_to?(:roles) ? membership.roles.to_a : []
    end

    def configured_role_ids(setting_key)
      Array(settings[setting_key]).reject(&:blank?).map(&:to_i)
    end

    def role_has_permission?(role, permission)
      if role.respond_to?(:has_permission?)
        role.has_permission?(permission)
      elsif role.respond_to?(:permissions)
        Array(role.permissions).compact.map(&:to_sym).include?(permission.to_sym)
      else
        false
      end
    end
  end
end
