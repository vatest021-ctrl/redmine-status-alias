module RedmineStatusAlias
  module IssueStatusPatch
    extend ActiveSupport::Concern

    def name
      RedmineStatusAlias::Settings.visible_name_for(self) || RedmineStatusAlias::Settings.raw_status_name(self)
    end
  end
end
