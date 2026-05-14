module RedmineStatusAlias
  module IntouchPatch
    module_function

    def apply!
      apply_issue_formatable_patch
      apply_regular_message_patches
      apply_message_formatter_patch
    end

    def apply_issue_formatable_patch
      return unless defined?(::Intouch::Support::IssueFormatable)
      return if ::Intouch::Support::IssueFormatable.ancestors.include?(IssueFormatablePatch)

      ::Intouch::Support::IssueFormatable.prepend(IssueFormatablePatch)
    end

    def apply_regular_message_patches
      if defined?(::Intouch::Regular::Message::Private) &&
          !::Intouch::Regular::Message::Private.ancestors.include?(RegularPrivatePatch)
        ::Intouch::Regular::Message::Private.prepend(RegularPrivatePatch)
      end

      if defined?(::Intouch::Regular::Message::Base) &&
          !::Intouch::Regular::Message::Base.ancestors.include?(RegularBasePatch)
        ::Intouch::Regular::Message::Base.prepend(RegularBasePatch)
      end
    end

    def apply_message_formatter_patch
      return unless defined?(::Intouch::Message::Formatter)
      return if ::Intouch::Message::Formatter.ancestors.include?(MessageFormatterPatch)

      ::Intouch::Message::Formatter.prepend(MessageFormatterPatch)
    end

    module Common
      private

      def redmine_status_alias_issue
        respond_to?(:issue) ? issue : self
      end

      def redmine_status_alias_project
        redmine_status_alias_issue.project if redmine_status_alias_issue.respond_to?(:project)
      end

      def redmine_status_alias_recipient(user_id)
        User.find_by(id: user_id) if user_id.present?
      rescue StandardError
        nil
      end

      def redmine_status_alias_force_alias?(recipient)
        recipient.blank? && RedmineStatusAlias::Settings.force_aliases_for_recipientless_channels?
      end

      def redmine_status_alias_context(user_id = nil, issue: redmine_status_alias_issue)
        recipient = redmine_status_alias_recipient(user_id)
        RedmineStatusAlias::Channel.with_recipient(
          recipient,
          issue: issue,
          project: redmine_status_alias_project,
          force_alias: redmine_status_alias_force_alias?(recipient)
        ) do
          yield
        end
      end
    end

    module IssueFormatablePatch
      include Common

      def as_markdown(user_id: nil)
        redmine_status_alias_context(user_id) { super(user_id: user_id) }
      end

      def as_html(user_id: nil)
        redmine_status_alias_context(user_id) { super(user_id: user_id) }
      end

      private

      def updated_status_text
        status_journal = journal.details.find_by(prop_key: %w[status status_id])
        return super unless status_journal

        RedmineStatusAlias::Channel.status_change_text(
          status_journal.old_value,
          status,
          issue: redmine_status_alias_issue,
          project: redmine_status_alias_project,
          recipient: RedmineStatusAlias::Context.user,
          force_alias: RedmineStatusAlias::Context.force_alias?
        )
      end
    end

    module RegularPrivatePatch
      include Common

      def message
        redmine_status_alias_context(user&.id, issue: issue) { super }
      end
    end

    module RegularBasePatch
      include Common

      def base_message
        if RedmineStatusAlias::Context.user || RedmineStatusAlias::Context.force_alias?
          super
        else
          redmine_status_alias_context(nil, issue: issue) { super }
        end
      end
    end

    module MessageFormatterPatch
      def status
        "#{I18n.t('field_status')}: #{RedmineStatusAlias::Channel.status_name(@status, issue: issue)}"
      end
    end
  end
end
