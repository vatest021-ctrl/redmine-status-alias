module RedmineStatusAlias
  module Context
    PROJECT_KEY = :redmine_status_alias_project

    module_function

    def project
      Thread.current[PROJECT_KEY]
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
