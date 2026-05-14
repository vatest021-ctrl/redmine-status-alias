module RedmineStatusAlias
  module IssuesHelperPatch
    def show_detail(detail, no_html = false, options = {})
      project = status_detail_project(detail)

      if project
        RedmineStatusAlias::Context.with_project(project) { super(detail, no_html, options) }
      else
        super(detail, no_html, options)
      end
    end

    def find_name_by_reflection(field, id)
      if field.to_s == "status"
        project = RedmineStatusAlias::Context.project
        return RedmineStatusAlias::Settings.visible_name_for_status_id(id, project: project) if project
      end

      super
    end

    private

    def status_detail_project(detail)
      return unless detail.respond_to?(:property) && detail.respond_to?(:prop_key)
      return unless detail.property == "attr" && detail.prop_key == "status_id"
      return unless detail.respond_to?(:journal)

      issue = detail.journal&.journalized
      issue.project if issue.respond_to?(:project)
    end
  end
end
