module Jennifer
  module Migration
    abstract class Base
      module AbstractClassMethods
        # Returns migration version - timestamp part of a class file name.
        abstract def version
      end

      extend AbstractClassMethods

      # :nodoc:
      macro delegate(*methods, to object, prefix pref = "")
        {% for method in methods %}
          def {{method.id}}(*args, **options)
            {{object.id}}.{{pref.id}}{{method.id}}(*args, **options)
          end

          def {{method.id}}(*args, **options)
            {{object.id}}.{{pref.id}}{{method.id}}(*args, **options) do |*yield_args|
              yield *yield_args
            end
          end
        {% end %}
      end

      macro inherited
        # :nodoc:
        def self.version
          matched_data = File.basename(__FILE__, ".cr").match(/\A(\d)+/)
          return matched_data[0] if matched_data
          raise "#{self} migration class has no specified version"
        end
      end

      delegate adapter, to: Adapter

      delegate create_data_type, to: adapter
      delegate :table_exists?, :index_exists?, :column_exists?, :view_exists?, :foreign_key_exists?, to: adapter
      delegate schema_processor, to: adapter

      delegate create_table, create_join_table, drop_join_table, exec, drop_table,
        change_table, create_view, create_materialized_view, drop_materialized_view,
        drop_view, add_index, drop_index, create_enum, drop_enum, change_enum,
        add_foreign_key, drop_foreign_key,
        to: schema_processor, prefix: "build_"

      def adapter_class
        adapter.class
      end

      abstract def up
      abstract def down

      # After failed #up method invocation.
      def after_up_failure
      end

      # After failed #down method invocation.
      def after_down_failure
      end

      # Returns migration timestamp.
      def self.version
        raise AbstractMethod.new(self, :version)
      end

      # Returns all existing migration timestamps based on available classes.
      def self.versions
        migrations.keys
      end

      # Returns all available migration classes.
      def self.migrations
        {% begin %}
          {% if @type.all_subclasses.size > 0 %}
            {
              {% for model in @type.all_subclasses %}
                {{model.id}}.version => {{model.id}},
              {% end %}
            }
          {% else %}
            {} of String => Jennifer::Migration::Base.class
          {% end %}
        {% end %}
      end
    end
  end
end

require "../adapter/schema_processor"
