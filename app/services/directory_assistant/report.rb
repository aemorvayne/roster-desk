class DirectoryAssistant
  class Report
    LIST_LIMIT = 20
    EMAIL_DOMAIN_PART = 2
    GROUP_COLUMNS = { 'status' => :status, 'job_position' => :job_position,
                      'email_domain' => Arel.sql("split_part(lower(email), '@', #{EMAIL_DOMAIN_PART})") }.freeze
    attr_reader :plan, :users
    def initialize(plan, scope)
      @plan = plan
      @users = Query.new(scope, plan.fetch('groups')).call
    end

    def intent
      plan.fetch('intent')
    end

    def text
      return unsupported_message if intent == 'unsupported'
      return "#{intent == 'select' ? 'Selected' : 'Showing'} #{size_label}." unless intent == 'answer'
      answer_text
    end

    def answer_text
      return breakdown if plan.fetch('metric') == 'breakdown'
      return list if plan.fetch('metric') == 'list'
      count_text
    end

    def count_text
      status = status_filter
      return "#{size_label} #{users.one? ? 'is' : 'are'} #{status}." if status
      return "#{size_label} in total." if plan.fetch('groups').empty?
      "I found #{size_label} matching your criteria."
    end

    def status_filter
      groups = plan.fetch('groups')
      return unless groups.one? && groups.first.fetch('conditions').one?
      condition = groups.first.fetch('conditions').first
      return unless condition.values_at('field', 'operator') == %w[status equals]
      condition.fetch('value').downcase.presence_in(User::STATUSES)
    end

    def size_label
      ActionController::Base.helpers.pluralize(users.count, 'user')
    end

    def selected_ids
      intent == 'select' ? users.ids : []
    end

    def visible_users
      intent == 'filter' ? users : User.all
    end

    def breakdown
      counts = users.group(GROUP_COLUMNS.fetch(plan.fetch('group_by'))).count
      return count_text if counts.empty?
      entries = counts.sort_by { |label, count| [-count, label.to_s] }
      "#{size_label} in total: #{entries.map { |entry| group_label(*entry) }.join('; ')}."
    end

    def group_label(label, count)
      label = label.presence || 'Not specified'
      label = label.capitalize if plan.fetch('group_by') == 'status'
      "#{label}: #{count}"
    end

    def list
      names = users.recent.limit(LIST_LIMIT).pluck(:full_name, :email)
      return count_text if names.empty?
      "#{count_text} #{list_heading(names)}: #{user_labels(names)}."
    end

    def list_heading(names)
      names.one? ? 'Here is the user' : "Here are #{names.size} of them"
    end

    def user_labels(names)
      names.map { |name, email| "#{name} (#{email})" }.join('; ')
    end

    def unsupported_message
      'I can count, list, group, filter, or select users by name, email, job title, status, and last sign-in. ' \
        'Use the toolbar to block, unblock, or delete accounts.'
    end
  end
end
