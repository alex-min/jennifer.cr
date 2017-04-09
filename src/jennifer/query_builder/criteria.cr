module Jennifer
  module QueryBuilder
    class Criteria
      alias Rightable = Criteria | DBAny | Array(DBAny)

      getter rhs : Rightable, relation : String?
      getter operator, field, table

      @rhs = ""
      @operator = :bool
      @negative = false

      def initialize(@field : String, @table : String, @relation = nil)
      end

      def set_relation(table, name)
        @relation = name if @relation.nil? && @table == table
        @rhs.as(Criteria).set_relation(table, name) if @rhs.is_a?(Criteria)
      end

      def alias_tables(aliases)
        @table = aliases[@relation.as(String)] if @relation
        @rhs.as(Criteria).alias_tables(aliases) if @rhs.is_a?(Criteria)
      end

      def change_table(old_name, new_name)
        if @table == old_name
          @table = new_name
          @relation = nil
        end
        @rhs.as(Criteria).change_table(old_name, new_name) if @rhs.is_a?(Criteria)
      end

      {% for op in [:<, :>, :<=, :>=, :+, :-, :*, :/] %}
        def {{op.id}}(value : Rightable)
          @rhs = value
          @operator = Operator.new({{op}})
          self
        end
      {% end %}

      def =~(value : String)
        regexp(value)
      end

      def regexp(value : String)
        @rhs = value
        @operator = Operator.new(:regexp)
        self
      end

      def not_regexp(value : String)
        @rhs = value
        @operator = Operator.new(:not_regexp)
        self
      end

      def like(value : String)
        @rhs = value
        @operator = Operator.new(:like)
        self
      end

      def not_like(value : String)
        @rhs = value
        @operator = Operator.new(:not_like)
        self
      end

      # postgres only
      def similar(value : String)
        @rhs = value
        @operator = Operator.new(:similar)
        self
      end

      def ==(value : Rightable)
        if !value.nil?
          @rhs = value
          @operator = Operator.new(:==)
        else
          is(value)
        end
        self
      end

      def !=(value : Rightable)
        if !value.nil?
          @rhs = value
          @operator = Operator.new(:!=)
        else
          not(value)
        end
        self
      end

      def is(value : Symbol | Bool | Nil)
        @rhs = translate(value)
        @operator = Operator.new(:is)
        self
      end

      def not(value : Symbol | Bool | Nil)
        @rhs = translate(value)
        @operator = Operator.new(:is_not)
        self
      end

      def not
        @negative = !@negative
        self
      end

      def in(arr : Array)
        raise ArgumentError.new("IN array can't be empty") if arr.empty?
        @rhs = arr.map { |e| e.as(DBAny) }
        @operator = :in
        self
      end

      def &(other : Criteria | LogicOperator)
        op = And.new
        op.add(self)
        op.add(other)
        op
      end

      def |(other : Criteria | LogicOperator)
        op = Or.new
        op.add(self)
        op.add(other)
        op
      end

      def to_s
        to_sql
      end

      def filter_out(arg)
        if arg.is_a?(Criteria)
          arg.to_sql
        else
          ::Jennifer::Adapter.escape_string(1)
        end
      end

      def to_sql
        _field = "#{@table}.#{@field.to_s}"
        str =
          case @operator
          when :bool
            _field
          when :in
            "#{_field} IN(#{::Jennifer::Adapter.escape_string(@rhs.as(Array).size)})"
          else
            "#{_field} #{@operator.to_s} #{@operator.as(Operator).filterable_rhs? ? filter_out(@rhs) : @rhs}"
          end
        str = "NOT (#{str})" if @negative
        str
      end

      def sql_args : Array(DB::Any)
        res = [] of DB::Any
        if filterable?
          if @operator == :in
            @rhs.as(Array).each do |e|
              res << e.as(DB::Any) unless e.is_a?(Criteria)
            end
          elsif !@rhs.is_a?(Criteria)
            res << @rhs.as(DB::Any)
          end
        end
        res
      end

      private def filterable?
        return false if @operator == :bool
        @operator.is_a?(Operator) ? @operator.as(Operator).filterable_rhs? : true
      end

      private def translate(value : Symbol | Bool | Nil)
        case value
        when :nil, nil
          "NULL"
        when :unknown
          "UNKNOWN"
        when true
          "TRUE"
        when false
          "FALSE"
        end
      end
    end
  end
end
