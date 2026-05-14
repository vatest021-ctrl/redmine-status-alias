module RedmineStatusAlias
  module Settings
    DEFAULTS = {
      "client_role_ids" => [],
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

    def status_aliases
      aliases = settings["status_aliases"]
      aliases.is_a?(Hash) ? aliases : {}
    end

    def alias_status_id_for(status_id)
      value = status_aliases[status_id.to_s]
      value.present? ? value.to_i : nil
    end

    def visible_name_for(status, user: User.current, project: nil)
      return unless enabled_for_project?(project)
      return unless applies_to_user?(user, project: project)

      alias_id = alias_status_id_for(status.id)
      return if alias_id.blank? || alias_id == status.id

      alias_status = IssueStatus.find_by(id: alias_id)
      return unless alias_status

      raw_status_name(alias_status)
    rescue StandardError => e
      Rails.logger.warn("[redmine_status_alias] Failed to resolve status alias: #{e.class}: #{e.message}") if defined?(Rails)
      nil
    end

    def raw_status_name(status)
      if status.respond_to?(:read_attribute)
        status.read_attribute(:name)
      else
        status.name
      end
    end

    def applies_to_user?(user, project: nil)
      return false if user.blank?
      return false if user.respond_to?(:admin?) && user.admin?

      selected_role_ids = client_role_ids
      return false if selected_role_ids.empty?

      (role_ids_for(user, project: project) & selected_role_ids).any?
    end

    def role_ids_for(user, project: nil)
      ids = []

      if user.respond_to?(:anonymous?) && user.anonymous? && defined?(Role)
        anonymous_role = Role.respond_to?(:anonymous) ? Role.anonymous : nil
        ids << anonymous_role.id if anonymous_role
      end

      if user.respond_to?(:memberships)
        memberships = user.memberships.to_a
        memberships = memberships.select { |membership| membership.project_id == project.id } if project

        ids.concat(memberships.flat_map { |membership| membership.respond_to?(:roles) ? membership.roles.map(&:id) : [] })
      end

      ids.compact.uniq
    end
  end
end
