module RedmineStatusAlias
  module Context
    PROJECT_KEY = :redmine_status_alias_project
    USER_KEY = :redmine_status_alias_user

    module_function

    def project
      Thread.current[PROJECT_KEY]
    end

    def user
      Thread.current[USER_KEY]
    end

    def with(project: nil, user: nil)
      previous_project = Thread.current[PROJECT_KEY]
      previous_user = Thread.current[USER_KEY]
      Thread.current[PROJECT_KEY] = project
      Thread.current[USER_KEY] = user
      yield
    ensure
      Thread.current[PROJECT_KEY] = previous_project
      Thread.current[USER_KEY] = previous_user
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
