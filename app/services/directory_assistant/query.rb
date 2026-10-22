class DirectoryAssistant
  class Query
    def initialize(scope, groups)
      @scope = scope
      @groups = groups
    end

    def call
      return @scope if @groups.empty?
      @scope.where(@groups.map { |group| predicate(group) }.reduce(:or))
    end

    def predicate(group)
      group.fetch('conditions').map { |condition| Condition.new(condition).to_arel }.reduce(:and)
    end
  end
end
