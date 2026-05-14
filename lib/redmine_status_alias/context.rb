module RedmineStatusAlias
  module Context
    PROJECT_KEY = :redmine_status_alias_project
    USER_KEY = :redmine_status_alias_user
    FORCE_ALIAS_KEY = :redmine_status_alias_force_alias

    module_function

    def project
      Thread.current[PROJECT_KEY]
    end

    def user
      Thread.current[USER_KEY]
    end

    def force_alias?
      Thread.current[FORCE_ALIAS_KEY] == true
    end

    def with(project: nil, user: nil, force_alias: nil)
      previous_project = Thread.current[PROJECT_KEY]
      previous_user = Thread.current[USER_KEY]
      previous_force_alias = Thread.current[FORCE_ALIAS_KEY]
      Thread.current[PROJECT_KEY] = project
      Thread.current[USER_KEY] = user
      Thread.current[FORCE_ALIAS_KEY] = force_alias unless force_alias.nil?
      yield
    ensure
      Thread.current[PROJECT_KEY] = previous_project
      Thread.current[USER_KEY] = previous_user
      Thread.current[FORCE_ALIAS_KEY] = previous_force_alias
    end

    def with_project(project)
      previous_project = Thread.current[PROJECT_KEY]
      Thread.current[PROJECT_KEY] = project
      yield
    ensure
      Thread.current[PROJECT_KEY] = previous_project
    end
  end
end
