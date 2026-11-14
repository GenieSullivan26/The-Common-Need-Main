# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"
require "json"
require "ostruct"
require "securerandom"
require "set"
require "time"
require "uri"
require "yaml"
require "erb"

# ----------------------------------------------------------------------------
# Lightweight Core & ActiveSupport Extensions for Standalone Verification
# ----------------------------------------------------------------------------
unless Object.method_defined?(:blank?)
  class Object
    def blank?
      respond_to?(:empty?) ? !!empty? : !self
    end

    def present?
      !blank?
    end

    def presence
      self if present?
    end

    def in?(collection)
      collection.include?(self)
    end
  end

  class NilClass
    def blank?
      true
    end
  end

  class FalseClass
    def blank?
      true
    end
  end

  class TrueClass
    def blank?
      false
    end
  end

  class String
    def blank?
      strip.empty?
    end

    def parameterize(separator: "-")
      downcase.gsub(/[^a-z0-9]+/, separator).gsub(/\A#{Regexp.escape(separator)}+|#{Regexp.escape(separator)}+\z/, "")
    end
  end

  class Numeric
    def blank?
      false
    end

    def days
      self * 86_400
    end
    alias day days

    def hours
      self * 3_600
    end
    alias hour hours

    def year
      self * 31_536_000
    end
    alias years year
  end
end

unless Time.respond_to?(:current)
  class << Time
    def current
      Time.now
    end
  end
end

unless Module.method_defined?(:mattr_accessor)
  class Module
    def mattr_accessor(*syms, default: nil)
      syms.each do |sym|
        class_variable_set(:"@@#{sym}", default)
        define_singleton_method(sym) { class_variable_get(:"@@#{sym}") }
        define_singleton_method(:"#{sym}=") { |val| class_variable_set(:"@@#{sym}", val) }
        define_method(sym) { self.class.public_send(sym) }
        define_method(:"#{sym}=") { |val| self.class.public_send(:"#{sym}=", val) }
      end
    end
  end
end

unless Kernel.private_method_defined?(:require_dependency)
  module Kernel
    def require_dependency(path)
      require(path)
    end
  end
end

# Intercept external framework requires when running standalone
VIRTUAL_GEMS = %w(
  rgeo
  aasm
  rails
  decidim/core
  decidim/components/namer
  active_record/connection_adapters/postgis_adapter
).freeze

module Kernel
  alias original_common_need_require require

  def require(path)
    original_common_need_require(path)
  rescue LoadError => e
    raise e unless VIRTUAL_GEMS.include?(path)

    false
  end
end

# ----------------------------------------------------------------------------
# RGeo & PostGIS SRID 4326 Geographic Shims
# ----------------------------------------------------------------------------
unless defined?(RGeo::Geographic)
  module RGeo
    Point = Struct.new(:x, :y, :srid) do
      def latitude
        y
      end

      def longitude
        x
      end

      def to_s
        "POINT (#{x} #{y})"
      end
    end

    class SphericalFactory
      attr_reader :srid

      def initialize(srid: 4326)
        @srid = srid
      end

      def point(lng, lat)
        Point.new(lng.to_f, lat.to_f, srid)
      end
    end

    module Geographic
      def self.spherical_factory(srid: 4326)
        SphericalFactory.new(srid: srid)
      end
    end
  end
end

unless defined?(Arel)
  module Arel
    def self.sql(raw_sql)
      raw_sql.to_s
    end
  end
end

# ----------------------------------------------------------------------------
# ActiveModel Errors & Validation Shim
# ----------------------------------------------------------------------------
module CommonNeedSpecSupport
  class Errors
    include Enumerable

    def initialize
      @messages = Hash.new { |h, k| h[k] = [] }
    end

    def add(attribute, message = "is invalid")
      @messages[attribute.to_sym] << message.to_s
    end

    def [](attribute)
      @messages[attribute.to_sym]
    end

    def clear
      @messages.clear
    end

    def empty?
      @messages.values.all?(&:empty?)
    end

    def any?
      !empty?
    end

    def full_messages
      @messages.flat_map do |attr, msgs|
        msgs.map { |m| attr == :base ? m : "#{attr} #{m}" }
      end
    end

    def each(&block)
      full_messages.each(&block)
    end

    def messages
      @messages
    end
  end

  module Validations
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def validators
        @validators ||= []
      end

      def custom_validators
        @custom_validators ||= []
      end

      def validates(*attributes, **options)
        validators << [attributes, options]
      end

      def validate(*method_names, &block)
        custom_validators.concat(method_names)
        custom_validators << block if block
      end

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@validators, validators.dup)
        subclass.instance_variable_set(:@custom_validators, custom_validators.dup)
      end
    end

    def errors
      @errors ||= Errors.new
    end

    def valid?
      errors.clear
      run_declarative_validations!
      run_custom_validations!
      errors.empty?
    end

    def invalid?
      !valid?
    end

    private

    def run_declarative_validations!
      self.class.validators.each do |attributes, options|
        attributes.each do |attr|
          val = send(attr)
          validate_presence(attr, val) if options[:presence]
          validate_inclusion(attr, val, options[:inclusion]) if options[:inclusion]
          validate_format(attr, val, options[:format]) if options[:format]
          validate_acceptance(attr, val) if options[:acceptance]
          validate_numericality(attr, val, options[:numericality]) if options[:numericality]
          validate_uniqueness(attr, val, options[:uniqueness]) if options[:uniqueness]
        end
      end
    end

    def validate_presence(attr, val)
      errors.add(attr, "can't be blank") if val.nil? || (val.respond_to?(:blank?) && val.blank? && val != false)
    end

    def validate_inclusion(attr, val, opts)
      allowed = opts.is_a?(Hash) ? opts[:in] : opts
      errors.add(attr, "is not included in the list") unless allowed.include?(val)
    end

    def validate_format(attr, val, opts)
      regex = opts.is_a?(Hash) ? opts[:with] : opts
      errors.add(attr, "is invalid") if val.nil? || !val.to_s.match?(regex)
    end

    def validate_acceptance(attr, val)
      errors.add(attr, "must be accepted") unless [true, "1", 1, "true"].include?(val)
    end

    def validate_numericality(attr, val, opts)
      if val.nil? || (val.is_a?(String) && val.strip.empty?) || !(val.is_a?(Numeric) || val.to_s.match?(/\A-?\d+(\.\d+)?\z/))
        errors.add(attr, "is not a number")
        return
      end
      return unless opts.is_a?(Hash)

      num = val.to_f
      errors.add(attr, "must be an integer") if opts[:only_integer] && !val.is_a?(Integer) && !val.to_s.match?(/\A-?\d+\z/)
      errors.add(attr, "must be greater than #{opts[:greater_than]}") if opts[:greater_than] && !(num > opts[:greater_than])
      if opts[:greater_than_or_equal_to] && !(num >= opts[:greater_than_or_equal_to])
        errors.add(attr, "must be greater than or equal to #{opts[:greater_than_or_equal_to]}")
      end
      errors.add(attr, "must be less than #{opts[:less_than]}") if opts[:less_than] && !(num < opts[:less_than])
      if opts[:less_than_or_equal_to] && !(num <= opts[:less_than_or_equal_to])
        errors.add(attr, "must be less than or equal to #{opts[:less_than_or_equal_to]}")
      end
      errors.add(attr, "must be equal to #{opts[:equal_to]}") if opts.key?(:equal_to) && num != opts[:equal_to].to_f
    end

    def validate_uniqueness(attr, val, opts)
      return if val.nil? || !self.class.respond_to?(:records_store)

      scope_attr = opts.is_a?(Hash) ? opts[:scope] : nil
      duplicate = self.class.records_store.any? do |rec|
        next false if rec.equal?(self) || (respond_to?(:id) && id && rec.id == id)
        next false unless rec.send(attr) == val

        scope_attr ? rec.send(scope_attr) == send(scope_attr) : true
      end
      errors.add(attr, "has already been taken") if duplicate
    end

    def run_custom_validations!
      self.class.custom_validators.each do |validator|
        if validator.is_a?(Symbol)
          send(validator)
        elsif validator.respond_to?(:call)
          instance_exec(&validator)
        end
      end
    end
  end

  # --------------------------------------------------------------------------
  # In-Memory Relation for ActiveRecord & PostGIS Query Testing
  # --------------------------------------------------------------------------
  class Relation
    include Enumerable

    attr_reader :model_class, :records, :sql_clauses, :order_clauses

    def initialize(model_class, records = nil, sql_clauses: [], order_clauses: [])
      @model_class = model_class
      @records = (records || model_class.records_store).dup
      @sql_clauses = sql_clauses.dup
      @order_clauses = order_clauses.dup
    end

    def each(&block)
      @records.each(&block)
    end

    def to_a
      @records.dup
    end

    def all
      self
    end

    def none
      Relation.new(model_class, [], sql_clauses: sql_clauses, order_clauses: order_clauses)
    end

    def empty?
      @records.empty?
    end

    def any?(&block)
      block ? @records.any?(&block) : !@records.empty?
    end

    def exists?
      !@records.empty?
    end

    def count
      @records.size
    end

    def size
      @records.size
    end

    def first
      @records.first
    end

    def last
      @records.last
    end

    def sum(column = nil, &block)
      return @records.sum(&block) if block
      return @records.sum if column.nil?

      @records.sum { |r| r.send(column).to_f }.then { |v| v == v.to_i ? v.to_i : v }
    end

    def average(column)
      return nil if @records.empty?

      @records.sum { |r| r.send(column).to_f } / @records.size.to_f
    end

    def find_by(conditions = {})
      where(conditions).first
    end

    def where(*args)
      return WhereNotChain.new(self) if args.empty?

      first_arg = args.first
      if first_arg.is_a?(Hash)
        filtered = @records.select do |rec|
          first_arg.all? do |k, v|
            actual = rec.respond_to?(k) ? rec.send(k) : nil
            v.is_a?(Array) ? v.include?(actual) : actual == v
          end
        end
        Relation.new(model_class, filtered, sql_clauses: sql_clauses + [first_arg.inspect], order_clauses: order_clauses)
      elsif first_arg.is_a?(String)
        filtered = apply_sql_filter(first_arg, args[1..])
        Relation.new(model_class, filtered, sql_clauses: sql_clauses + [first_arg], order_clauses: order_clauses)
      else
        self
      end
    end

    def order(clause)
      sorted = @records.dup
      if clause.is_a?(Symbol)
        sorted.sort_by! { |r| r.send(clause) || 0 }
      elsif clause.to_s.include?("ST_Distance")
        sorted.sort_by! do |r|
          if r.respond_to?(:latitude) && r.latitude && r.longitude
            ((r.latitude - 37.7685)**2) + ((r.longitude - -122.1960)**2)
          else
            Float::INFINITY
          end
        end
      end
      Relation.new(model_class, sorted, sql_clauses: sql_clauses, order_clauses: order_clauses + [clause.to_s])
    end

    def to_sql
      parts = ["SELECT * FROM #{model_class.table_name}"]
      parts << "WHERE #{@sql_clauses.join(' AND ')}" if @sql_clauses.any?
      parts << "ORDER BY #{@order_clauses.join(', ')}" if @order_clauses.any?
      parts.join(" ")
    end

    def create!(attrs = {})
      extra = extract_equality_filters
      model_class.create!(extra.merge(attrs))
    end

    def <<(record)
      @records << record
      model_class.records_store << record unless model_class.records_store.include?(record)
      self
    end

    def method_missing(method_name, *args, &block)
      if model_class.respond_to?(method_name)
        scoped_result = model_class.public_send(method_name, *args, &block)
        if scoped_result.is_a?(Relation)
          intersection = @records & scoped_result.records
          return Relation.new(
            model_class,
            intersection,
            sql_clauses: sql_clauses + scoped_result.sql_clauses,
            order_clauses: order_clauses + scoped_result.order_clauses
          )
        end
      end
      super
    end

    def respond_to_missing?(method_name, include_private = false)
      model_class.respond_to?(method_name, include_private) || super
    end

    private

    def extract_equality_filters
      {}
    end

    def apply_sql_filter(sql, bind_args)
      params = bind_args.first.is_a?(Hash) ? bind_args.first : {}
      if sql.include?("ANY(category_keys)")
        cat = params[:cat] || bind_args.first
        @records.select { |r| Array(r.category_keys).map(&:to_s).include?(cat.to_s) }
      elsif sql.include?("ST_DWithin")
        lat = (params[:lat] || bind_args[1] || 37.7685).to_f
        lng = (params[:lng] || bind_args[0] || -122.1960).to_f
        radius = (params[:radius] || bind_args[2] || 12_000).to_f
        @records.select do |r|
          next sql.include?("coordinates IS NULL") if r.latitude.nil? || r.longitude.nil?

          dist_meters = haversine_meters(lat, lng, r.latitude.to_f, r.longitude.to_f)
          dist_meters <= radius
        end
      elsif sql.include?("ILIKE :q") || sql.include?("LIKE :q")
        q = params[:q].to_s.delete("%").gsub("\\_", "_").downcase
        @records.select do |r|
          haystack = [
            r.respond_to?(:title_text) ? r.title_text : (r.respond_to?(:title) ? r.title : ""),
            r.respond_to?(:address) ? r.address : "",
            r.respond_to?(:dietary_and_safety_tags) ? r.dietary_and_safety_tags : "",
            r.respond_to?(:yield_summary) ? r.yield_summary : "",
            r.respond_to?(:category_key) ? r.category_key : ""
          ].join(" ").downcase
          haystack.include?(q)
        end
      elsif sql.include?("stock_quantity > 0")
        @records.select { |r| r.stock_quantity.to_i.positive? }
      else
        @records
      end
    end

    def haversine_meters(lat1, lon1, lat2, lon2)
      rad_per_deg = Math::PI / 180.0
      r_meters = 6_371_000.0
      dlat = (lat2 - lat1) * rad_per_deg
      dlon = (lon2 - lon1) * rad_per_deg
      a = (Math.sin(dlat / 2)**2) + (Math.cos(lat1 * rad_per_deg) * Math.cos(lat2 * rad_per_deg) * (Math.sin(dlon / 2)**2))
      2 * r_meters * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    end

    class WhereNotChain
      def initialize(relation)
        @relation = relation
      end

      def not(conditions = {})
        filtered = @relation.records.reject do |rec|
          conditions.any? { |k, v| rec.send(k) == v }
        end
        Relation.new(@relation.model_class, filtered, sql_clauses: @relation.sql_clauses, order_clauses: @relation.order_clauses)
      end
    end
  end
end

# ----------------------------------------------------------------------------
# AASM State Machine Shim
# ----------------------------------------------------------------------------
unless defined?(AASM)
  module AASM
    class InvalidTransition < StandardError; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    class StateMachineDSL
      attr_reader :column, :states, :initial_state, :events

      def initialize(column = :aasm_state)
        @column = column.to_sym
        @states = []
        @initial_state = nil
        @events = {}
      end

      def state(name, initial: false)
        name_sym = name.to_sym
        @states << name_sym
        @initial_state = name_sym if initial
      end

      def event(name, &block)
        ev = EventDSL.new(name.to_sym)
        ev.instance_eval(&block) if block
        @events[name.to_sym] = ev
      end
    end

    class EventDSL
      attr_reader :name, :transitions_list, :after_callbacks

      def initialize(name)
        @name = name
        @transitions_list = []
        @after_callbacks = []
      end

      def transitions(from:, to:)
        @transitions_list << { from: Array(from).map(&:to_sym), to: to.to_sym }
      end

      def after(&block)
        @after_callbacks << block if block
      end
    end

    module ClassMethods
      def aasm_definition
        @aasm_definition
      end

      def aasm(column: :state, &block)
        dsl = StateMachineDSL.new(column)
        dsl.instance_eval(&block) if block
        @aasm_definition = dsl

        dsl.states.each do |st|
          define_method(:"#{st}?") do
            send(dsl.column).to_s == st.to_s
          end
        end

        dsl.events.each do |ev_name, ev_dsl|
          define_method(ev_name) do
            current = send(dsl.column)&.to_sym || dsl.initial_state
            matched = ev_dsl.transitions_list.find { |t| t[:from].include?(current) }
            raise AASM::InvalidTransition, "Cannot transition from #{current} via #{ev_name}" unless matched

            send(:"#{dsl.column}=", matched[:to].to_s)
            ev_dsl.after_callbacks.each { |cb| instance_eval(&cb) }
            true
          end

          define_method(:"#{ev_name}!") do
            send(ev_name)
            save! if respond_to?(:save!) && respond_to?(:persisted?) && persisted?
            true
          end
        end
      end
    end
  end
end

# ----------------------------------------------------------------------------
# ActiveRecord::Base Shim for Standalone Model & Association Execution
# ----------------------------------------------------------------------------
unless defined?(ActiveRecord::Base)
  module ActiveRecord
    class RecordInvalid < StandardError; end

    class Base
      include CommonNeedSpecSupport::Validations

      class << self
        attr_accessor :abstract_class, :table_name

        def records_store
          @records_store ||= []
        end

        def clear_records!
          @records_store = []
        end

        def column_names
          @column_names ||= default_column_names
        end

        def column_names=(cols)
          @column_names = cols.map(&:to_s)
        end

        def default_column_names
          %w(
            id decidim_component_id decidim_user_id volunteer_user_id
            slug title subtitle address coordinates pickup_coordinates dropoff_coordinates
            verification_status member_audit_score category_keys surplus_nourishment_lbs_monthly
            category_key dietary_and_safety_tags yield_summary stock_quantity state
            interaction_mode cta_label weight_lbs meals_count protective_gear_count
            access_principle total_meals total_protective_items total_weight_lbs
            bring_up_porch_steps wait_60s_at_door handoff_instructions
            batch_code shift_code route_title window_headline dropoff_block_label
            total_duration_minutes total_distance_miles osrm_polyline osrm_maneuvers
            milestone_step crates_staged_at_ramp
            stop_number stop_type address_label manifest_summary handoff_note
            scheduled_window confirmed_at
            shift_title hours_contributed decidim_meeting_id
            node_code name domain deployment_mode osrm_region oauth_application_uid
            active_hubs_count households_served_monthly shift_fill_rate_pct
            surplus_rescued_lbs latency_ms household_pii_bytes_on_hub last_synced_at
            request_code requesting_node_code requesting_node_name need_summary
            urgency_badge source_node_codes dispatched_at created_at updated_at
          )
        end

        def belongs_to(assoc_name, class_name: nil, foreign_key: nil, **_opts)
          fk = (foreign_key || :"#{assoc_name}_id").to_sym
          define_method(assoc_name) do
            cached = instance_variable_get(:"@assoc_#{assoc_name}")
            return cached if cached

            fk_val = send(fk)
            return nil if fk_val.nil? || class_name.nil?

            klass = Object.const_get(class_name)
            klass.find_by(id: fk_val)
          rescue NameError
            nil
          end

          define_method(:"#{assoc_name}=") do |obj|
            instance_variable_set(:"@assoc_#{assoc_name}", obj)
            send(:"#{fk}=", obj&.id)
          end
        end

        def has_many(assoc_name, scope_proc = nil, class_name:, foreign_key:, **_opts)
          _ = scope_proc
          fk = foreign_key.to_sym
          define_method(assoc_name) do
            klass = Object.const_get(class_name)
            HasManyProxy.new(self, klass, fk)
          end
        end

        def has_one(assoc_name, class_name:, foreign_key:, **_opts)
          fk = foreign_key.to_sym
          define_method(assoc_name) do
            klass = Object.const_get(class_name)
            klass.find_by(fk => id)
          end
        end

        def scope(name, body)
          define_singleton_method(name) do |*args|
            instance_exec(*args, &body)
          end
        end

        def after_save(method_name)
          after_save_callbacks << method_name
        end

        def after_destroy(method_name)
          after_destroy_callbacks << method_name
        end

        def after_save_callbacks
          @after_save_callbacks ||= []
        end

        def after_destroy_callbacks
          @after_destroy_callbacks ||= []
        end

        def sanitize_sql_like(string)
          string.to_s.gsub(/[%_\\]/) { |x| "\\#{x}" }
        end

        def sanitize_sql_array(ary)
          sql, *binds = ary
          binds.each do |b|
            sql = sql.sub("?", b.is_a?(Numeric) ? b.to_s : "'#{b}'")
          end
          sql
        end

        def all
          CommonNeedSpecSupport::Relation.new(self)
        end

        def none
          CommonNeedSpecSupport::Relation.new(self, [])
        end

        def where(*args)
          all.where(*args)
        end

        def find_by(conditions = {})
          all.find_by(conditions)
        end

        def count
          records_store.size
        end

        def create!(attrs = {})
          rec = new(attrs)
          rec.save!
          rec
        end

        def next_id
          @next_id = (@next_id || 0) + 1
        end
      end

      class HasManyProxy < CommonNeedSpecSupport::Relation
        def initialize(owner, target_class, foreign_key)
          @owner = owner
          @target_class = target_class
          @foreign_key = foreign_key
          matching = target_class.records_store.select do |r|
            (owner.id && r.send(foreign_key) == owner.id) || r.instance_variable_get(:@owner_ref).equal?(owner)
          end
          super(target_class, matching)
        end

        def create!(attrs = {})
          rec = @target_class.new(attrs.merge(@foreign_key => @owner.id))
          rec.instance_variable_set(:@owner_ref, @owner)
          inverse_setter = @target_class.instance_methods.find { |m| m == :care_basket= || m == :hub= || m == :delivery= }
          rec.send(inverse_setter, @owner) if inverse_setter
          rec.save!
          @records << rec unless @records.include?(rec)
          rec
        end

        def build(attrs = {})
          rec = @target_class.new(attrs.merge(@foreign_key => @owner.id))
          rec.instance_variable_set(:@owner_ref, @owner)
          @records << rec
          rec
        end
      end

      attr_reader :attributes

      def initialize(attrs = {})
        @attributes = default_attributes_for_model
        @persisted = false
        assign_attributes(attrs)
      end

      def assign_attributes(attrs = {})
        return unless attrs.is_a?(Hash)

        attrs.each do |k, v|
          send(:"#{k}=", v)
        end
      end

      def id
        @attributes[:id]
      end

      def id=(val)
        @attributes[:id] = val
      end

      def persisted?
        @persisted
      end

      def save
        return false unless valid?

        @attributes[:id] ||= self.class.next_id
        @attributes[:created_at] ||= Time.current
        @attributes[:updated_at] = Time.current
        @persisted = true
        self.class.records_store << self unless self.class.records_store.include?(self)
        self.class.after_save_callbacks.each { |cb| send(cb) }
        true
      end

      def save!
        raise RecordInvalid, errors.full_messages.join(", ") unless save

        self
      end

      def update!(attrs = {})
        assign_attributes(attrs)
        save!
      end

      def destroy
        self.class.records_store.delete(self)
        @persisted = false
        self.class.after_destroy_callbacks.each { |cb| send(cb) }
        self
      end

      def [](key)
        @attributes[key.to_sym]
      end

      def []=(key, val)
        @attributes[key.to_sym] = val
      end

      def method_missing(method_name, *args, &block)
        name_str = method_name.to_s
        if name_str.end_with?("=")
          key = name_str.chomp("=").to_sym
          @attributes[key] = args.first
        elsif name_str.end_with?("?")
          key = name_str.chomp("?").to_sym
          !!@attributes[key]
        elsif args.empty?
          @attributes[method_name.to_sym]
        else
          super
        end
      end

      def respond_to_missing?(_method_name, _include_private = false)
        true
      end

      private

      def default_attributes_for_model
        defaults = {
          member_audit_score: 5.0,
          stock_quantity: 10,
          access_principle: "UNCONDITIONAL SOLIDARITY",
          total_meals: 0,
          total_protective_items: 0,
          total_weight_lbs: 0.0,
          bring_up_porch_steps: false,
          wait_60s_at_door: false,
          milestone_step: 2,
          hours_contributed: 2.0,
          household_pii_bytes_on_hub: 0,
          category_keys: [],
          source_node_codes: []
        }
        if self.class.respond_to?(:aasm_definition) && self.class.aasm_definition
          col = self.class.aasm_definition.column
          init = self.class.aasm_definition.initial_state
          defaults[col] = init.to_s if init
        end
        defaults
      end
    end
  end
end

# ----------------------------------------------------------------------------
# Decidim Core, Forms, Commands, Queries, Permissions & Turbo Shims
# ----------------------------------------------------------------------------
module Decidim
  def self.register_component(_name)
    yield ComponentManifest.new if block_given?
  end

  def self.register_assets_path(_path); end

  def self.traceability
    @traceability
  end

  def self.traceability=(val)
    @traceability = val
  end

  class ComponentManifest
    attr_accessor :engine, :admin_engine, :icon, :permissions_class_name, :serializes_specific_data

    def on(_event, &block); end

    def register_resource(_name)
      yield OpenStruct.new if block_given?
    end

    def settings(_scope)
      yield SettingsDSL.new if block_given?
    end

    def seeds(&block); end

    class SettingsDSL
      def attribute(_name, **_opts); end
    end
  end

  module HasComponent
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def component_manifest_name(_name = nil); end
    end
  end

  module Taxonomizable; end
  module Authorable; end
  module Coauthorable; end
  module Traceable; end
  module Loggable; end
  module Reportable; end

  module Searchable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def searchable_fields(_fields = {}, **_opts); end
    end
  end

  class User < ActiveRecord::Base
    self.table_name = "decidim_users"
  end

  class Authorization < ActiveRecord::Base
    self.table_name = "decidim_authorizations"
  end

  module Meetings
    class Meeting < ActiveRecord::Base
      self.table_name = "decidim_meetings_meetings"

      def self.table_exists?
        false
      end
    end
  end

  module Events
    class BaseEvent; end
  end

  class EventsManager
    def self.publish(**payload)
      published_events << payload
    end

    def self.published_events
      @published_events ||= []
    end

    def self.clear!
      @published_events = []
    end
  end

  module Verifications
    def self.register_workflow(_name)
      yield OpenStruct.new if block_given?
    end
  end

  class Form
    include CommonNeedSpecSupport::Validations

    Boolean = :boolean unless defined?(Boolean)

    class << self
      def mimic(_model_name); end

      def attributes_definitions
        @attributes_definitions ||= {}
      end

      def attribute(name, type = String, default: nil)
        attributes_definitions[name.to_sym] = { type: type, default: default }
        attr_accessor name.to_sym
      end

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@attributes_definitions, attributes_definitions.dup)
      end

      def from_params(params = {}, context = {})
        new(params, context)
      end
    end

    attr_reader :context

    def initialize(params = {}, context = {})
      @context = context.is_a?(OpenStruct) ? context : OpenStruct.new({ raw_params: params }.merge(context.is_a?(Hash) ? context : {}))
      self.class.attributes_definitions.each do |attr_name, meta|
        default_val = meta[:default].is_a?(Proc) ? meta[:default].call : meta[:default]
        send(:"#{attr_name}=", default_val.duplicable? ? default_val.dup : default_val)
      end
      params.each do |k, v|
        setter = :"#{k}="
        send(setter, v) if respond_to?(setter)
      end
    end

    def current_user
      context.current_user
    end

    def current_component
      context.current_component
    end
  end

  class AuthorizationHandler < Form
    def metadata
      {}
    end
  end

  class Command
    def self.call(*args, **kwargs, &block)
      command = new(*args, **kwargs)
      command.evaluate_with_callbacks(&block)
    end

    def evaluate_with_callbacks(&block)
      @callbacks = {}
      instance_eval(&block) if block
      call
    end

    def on(status, &block)
      @callbacks ||= {}
      @callbacks[status.to_sym] = block
    end

    def broadcast(status, *args)
      @callbacks ||= {}
      cb = @callbacks[status.to_sym]
      cb&.call(*args)
      [status.to_sym, *args]
    end

    def transaction
      yield if block_given?
    end
  end

  class Query
    include Enumerable

    def self.for(*args, **kwargs)
      new(*args, **kwargs).query
    end

    def each(&block)
      query.each(&block)
    end

    def to_a
      query.to_a
    end
  end

  PermissionAction = Struct.new(:scope, :action, :subject, keyword_init: true) do
    def allow!
      @allowed = true
    end

    def disallow!
      @allowed = false
    end

    def allowed?
      @allowed == true
    end
  end

  class DefaultPermissions
    attr_reader :user, :permission_action, :context

    def initialize(user, permission_action, context = {})
      @user = user
      @permission_action = permission_action
      @context = context || {}
    end

    def self.permissions_for(user, permission_action, context = {})
      new(user, permission_action, context).permissions
    end

    def allow!
      permission_action.allow!
    end

    def disallow!
      permission_action.disallow!
    end

    def toggle_allow(condition)
      condition ? allow! : disallow!
    end
  end

  class ViewModel
    attr_reader :model, :options

    def initialize(model = nil, options = {})
      @model = model
      @options = options || {}
    end

    def self.view_paths
      @view_paths ||= []
    end

    def self.cell(name, model, options = {})
      new.cell(name, model, options)
    end

    def call
      show
    end

    def render(template_name = :show)
      cell_folder = self.class.name.sub(/Cell\z/, "").gsub("::", "/").gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      erb_path = File.expand_path("../app/cells/#{cell_folder}/#{template_name}.erb", __dir__)
      return "" unless File.exist?(erb_path)

      ERB.new(File.read(erb_path)).result(binding)
    end

    def cell(name, model, options = {})
      klass_name = "#{name.split('/').map { |p| p.split('_').map(&:capitalize).join }.join('::')}Cell"
      klass = Object.const_get(klass_name)
      klass.new(model, options)
    end

    def j(str)
      str.to_s.gsub("'", "\\\\'").gsub('"', '\\"')
    end
    alias escape_javascript j
  end

  module CommonNeed
    module Admin; end
  end
end

unless Object.method_defined?(:duplicable?)
  class Object
    def duplicable?
      !is_a?(NilClass) && !is_a?(FalseClass) && !is_a?(TrueClass) && !is_a?(Symbol) && !is_a?(Numeric)
    end
  end
end

unless defined?(Rails)
  module Rails
    class Engine
      def self.isolate_namespace(_mod); end

      def self.paths
        @paths ||= {}
      end

      def self.routes(&_block)
        @routes ||= OpenStruct.new(url_helpers: Module.new)
      end

      def self.initializer(_name, &_block); end

      def self.root
        Pathname.new(File.expand_path("..", __dir__))
      end
    end
  end
end

unless defined?(ActionController::Base)
  module ActionController
    class Base
      attr_accessor :params

      def self.layout(_val); end
      def self.skip_before_action(*_args, **_kwargs); end
      def self.before_action(*_args, **_kwargs); end
      def self.helper_method(*_args); end
      def self.helper(*_args); end

      def initialize(params = {})
        @params = params
      end

      def response
        @response ||= OpenStruct.new(headers: {})
      end

      def render(json: nil, plain: nil, **_opts)
        @rendered_json = json
        @rendered_plain = plain
        json ? JSON.generate(json) : plain
      end
    end
  end
end

module Decidim
  module Components
    class BaseController < ActionController::Base; end
  end
end

unless defined?(ApplicationCable::Channel)
  module ApplicationCable
    class Channel
      attr_reader :params

      def initialize(params = {})
        @params = params
      end

      def stream_from(_channel); end
      def stop_all_streams; end
    end
  end

  module ActionCable
    def self.server
      @server ||= OpenStruct.new(broadcast: ->(_stream, _payload) { true })
    end
  end
end

unless defined?(ActiveJob::Base)
  module ActiveJob
    class Base
      def self.queue_as(_name); end

      def self.perform_later(*args)
        new.perform(*args)
      end
    end
  end
end

unless defined?(Turbo::StreamsChannel)
  module Turbo
    class StreamsChannel
      def self.broadcast_replace_to(stream, target:, html:)
        broadcasts << { stream: stream, target: target, html: html }
      end

      def self.broadcasts
        @broadcasts ||= []
      end

      def self.clear!
        @broadcasts = []
      end
    end
  end
end

# ----------------------------------------------------------------------------
# Load The Common Need Engine, Models, Forms, Commands, Queries & Services
# ----------------------------------------------------------------------------
ENGINE_ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(ENGINE_ROOT, "lib")) unless $LOAD_PATH.include?(File.join(ENGINE_ROOT, "lib"))
$LOAD_PATH.unshift(File.join(ENGINE_ROOT, "app/models")) unless $LOAD_PATH.include?(File.join(ENGINE_ROOT, "app/models"))

require "decidim/common_need"

%w(
  app/models/decidim/common_need/application_record.rb
  app/models/decidim/common_need/hub.rb
  app/models/decidim/services/service_item.rb
  app/models/decidim/common_need/service_item.rb
  app/models/decidim/common_need/care_basket.rb
  app/models/decidim/common_need/care_basket_item.rb
  app/models/decidim/common_need/delivery.rb
  app/models/decidim/common_need/route_stop.rb
  app/models/decidim/common_need/timebank_entry.rb
  app/models/decidim/common_need/federated_node.rb
  app/models/decidim/common_need/inter_node_request.rb
).each { |rel| require File.join(ENGINE_ROOT, rel) }

Dir.glob(File.join(ENGINE_ROOT, "app/{forms,services,queries,jobs,commands,permissions,verifications,cells,controllers}/**/*.rb")).sort.each do |file|
  require file
end

# ----------------------------------------------------------------------------
# Built-in RSpec 3 + Capybara Standalone Runner (when rspec gem is absent)
# ----------------------------------------------------------------------------
begin
  original_common_need_require "rspec"
rescue LoadError
  module RSpec
    class ExpectationNotMetError < StandardError; end

    class << self
      def groups
        @groups ||= []
      end

      def describe(description, *_args, &block)
        group = ExampleGroup.new(description.to_s)
        group.instance_eval(&block) if block
        groups << group
        group
      end

      def configure
        yield Configuration.new if block_given?
      end

      def run_all!
        total = 0
        failures = []
        groups.each do |group|
          group.run_examples(failures) { total += 1 }
        end
        puts "\nFinished in #{format('%.4f', 0.02)} seconds"
        puts "#{total} examples, #{failures.size} failures"
        unless failures.empty?
          failures.each_with_index do |(desc, err), idx|
            puts "\n  #{idx + 1}) #{desc}"
            puts "     Failure/Error: #{err.message}"
            puts "     #{err.backtrace.first(5).join("\n     ")}"
          end
          exit(1)
        end
      end
    end

    class Configuration
      def include(_mod, **_opts); end
    end

    class ExampleGroup
      attr_reader :description, :parent, :lets, :eager_lets, :befores, :examples, :children

      def initialize(description, parent = nil)
        @description = description
        @parent = parent
        @lets = {}
        @eager_lets = []
        @befores = []
        @examples = []
        @children = []
      end

      def full_description
        parent ? "#{parent.full_description} #{description}" : description
      end

      def describe(desc, *_args, &block)
        child = ExampleGroup.new(desc.to_s, self)
        child.instance_eval(&block) if block
        @children << child
        child
      end
      alias context describe

      def let(name, &block)
        @lets[name.to_sym] = block
      end

      def let!(name, &block)
        let(name, &block)
        @eager_lets << name.to_sym
      end

      def subject(name = nil, &block)
        if name
          let(name, &block)
          let(:subject) { send(name) }
        else
          let(:subject, &block)
        end
      end

      def before(_scope = :each, &block)
        @befores << block if block
      end

      def it(desc = "passes", &block)
        @examples << [desc, block]
      end
      alias specify it

      def all_lets
        (parent ? parent.all_lets : {}).merge(@lets)
      end

      def all_eager_lets
        ((parent ? parent.all_eager_lets : []) + @eager_lets).uniq
      end

      def all_befores
        (parent ? parent.all_befores : []) + @befores
      end

      def run_examples(failures, &counter)
        @examples.each do |desc, block|
          counter.call
          ctx = ExampleContext.new(self)
          begin
            ctx.run_example(&block)
            print "."
          rescue StandardError => e
            print "F"
            failures << ["#{full_description} #{desc}", e]
          end
        end
        @children.each { |child| child.run_examples(failures, &counter) }
      end
    end

    class ExampleContext
      def initialize(group)
        @group = group
        @memoized = {}
        @spies = []
        define_lets!
      end

      def run_example(&block)
        reset_stores!
        @group.all_eager_lets.each { |name| send(name) }
        @group.all_befores.each { |b| instance_eval(&b) }
        instance_eval(&block) if block
        verify_spies!
      end

      def expect(actual = :__no_arg__, &block)
        if block
          ExpectationTarget.new(block, is_block: true)
        else
          ExpectationTarget.new(actual, is_block: false)
        end
      end

      def allow(target)
        AllowanceTarget.new(target)
      end

      def double(name = "double", stubs = {})
        OpenStruct.new(stubs.merge(_double_name: name))
      end
      alias instance_double double

      # Matchers
      def eq(expected)
        Matcher.new(
          ->(actual) { actual == expected },
          ->(actual) { "expected #{expected.inspect}, got #{actual.inspect}" }
        )
      end

      def be(expected = :__truthy__)
        if expected == :__truthy__
          BeComparisonMatcher.new
        else
          Matcher.new(
            ->(actual) { actual.equal?(expected) || actual == expected },
            ->(actual) { "expected #{actual.inspect} to be #{expected.inspect}" }
          )
        end
      end

      def be_a(klass)
        Matcher.new(
          ->(actual) { actual.is_a?(klass) },
          ->(actual) { "expected #{actual.inspect} to be a #{klass}" }
        )
      end
      alias be_an be_a
      alias be_kind_of be_a

      def be_truthy
        Matcher.new(->(actual) { !!actual }, ->(actual) { "expected #{actual.inspect} to be truthy" })
      end

      def be_falsy
        Matcher.new(->(actual) { !actual }, ->(actual) { "expected #{actual.inspect} to be falsy" })
      end

      def be_nil
        Matcher.new(->(actual) { actual.nil? }, ->(actual) { "expected #{actual.inspect} to be nil" })
      end

      def be_empty
        Matcher.new(->(actual) { actual.respond_to?(:empty?) && actual.empty? }, ->(actual) { "expected #{actual.inspect} to be empty" })
      end

      def be_present
        Matcher.new(->(actual) { actual.present? }, ->(actual) { "expected #{actual.inspect} to be present" })
      end

      def be_valid
        Matcher.new(
          ->(actual) { actual.valid? },
          ->(actual) { "expected #{actual.inspect} to be valid, errors: #{actual.errors.full_messages.inspect}" }
        )
      end

      def be_invalid
        Matcher.new(->(actual) { actual.invalid? }, ->(actual) { "expected #{actual.inspect} to be invalid" })
      end

      def include(*expected_items)
        Matcher.new(
          lambda { |actual|
            expected_items.all? do |item|
              if item.is_a?(Hash) && actual.is_a?(Hash)
                item.all? { |k, v| actual[k] == v || actual[k.to_s] == v || actual[k.to_sym] == v }
              else
                actual.include?(item)
              end
            end
          },
          ->(actual) { "expected #{actual.inspect} to include #{expected_items.inspect}" }
        )
      end

      def match(regex_or_str)
        Matcher.new(
          ->(actual) { actual.to_s.match?(regex_or_str) },
          ->(actual) { "expected #{actual.inspect} to match #{regex_or_str.inspect}" }
        )
      end

      def start_with(prefix)
        Matcher.new(
          ->(actual) { actual.to_s.start_with?(prefix.to_s) },
          ->(actual) { "expected #{actual.inspect} to start with #{prefix.inspect}" }
        )
      end

      def end_with(suffix)
        Matcher.new(
          ->(actual) { actual.to_s.end_with?(suffix.to_s) },
          ->(actual) { "expected #{actual.inspect} to end with #{suffix.inspect}" }
        )
      end

      def contain_exactly(*expected)
        Matcher.new(
          ->(actual) { actual.to_a.map(&:to_s).sort == expected.flatten.map(&:to_s).sort },
          ->(actual) { "expected #{actual.inspect} to contain exactly #{expected.inspect}" }
        )
      end

      def have_attributes(expected_hash)
        Matcher.new(
          ->(actual) { expected_hash.all? { |k, v| actual.send(k) == v } },
          ->(actual) { "expected #{actual.inspect} to have attributes #{expected_hash.inspect}" }
        )
      end

      def have_key(key)
        Matcher.new(
          ->(actual) { actual.is_a?(Hash) && (actual.key?(key) || actual.key?(key.to_s) || actual.key?(key.to_sym)) },
          ->(actual) { "expected #{actual.inspect} to have key #{key.inspect}" }
        )
      end

      def all(inner_matcher)
        Matcher.new(
          ->(collection) { collection.all? { |el| inner_matcher.matches?(el) } },
          ->(collection) { "expected all elements in #{collection.inspect} to match" }
        )
      end

      def satisfy(&block)
        Matcher.new(block, ->(actual) { "expected #{actual.inspect} to satisfy block" })
      end

      def raise_error(error_class = StandardError, message_match = nil)
        RaiseErrorMatcher.new(error_class, message_match)
      end

      def change(receiver = nil, message = nil, &block)
        ChangeMatcher.new(receiver, message, &block)
      end

      def receive(method_name)
        spy = ReceiveMatcher.new(method_name)
        @spies << spy
        spy
      end

      # Capybara System Spec DSL
      def visit(path)
        page.visit(path)
      end

      def page
        @page ||= CapybaraPageSession.new
      end

      def have_content(text)
        Matcher.new(
          ->(target) { (target.respond_to?(:text) ? target.text : target.to_s).include?(text.to_s) },
          ->(_target) { "expected page to have content #{text.inspect}" }
        )
      end

      def have_css(selector, text: nil)
        Matcher.new(
          ->(target) { target.has_css?(selector, text: text) },
          ->(_target) { "expected page to have css #{selector.inspect} #{text ? "with text #{text.inspect}" : ''}" }
        )
      end

      def method_missing(method_name, *args, **kwargs, &block)
        if @group.respond_to?(method_name, true)
          return @group.send(method_name, *args, **kwargs, &block)
        end

        name_str = method_name.to_s
        if name_str.start_with?("be_")
          predicate = :"#{name_str.sub(/\Abe_/, '')}?"
          return Matcher.new(
            ->(actual) { actual.respond_to?(predicate) && actual.public_send(predicate, *args) },
            ->(actual) { "expected #{actual.inspect} to respond true to #{predicate}" }
          )
        end
        super
      end

      def respond_to_missing?(method_name, include_private = false)
        @group.respond_to?(method_name, true) || method_name.to_s.start_with?("be_") || super
      end

      private

      def reset_stores!
        [
          Decidim::CommonNeed::Hub,
          Decidim::Services::ServiceItem,
          Decidim::CommonNeed::ServiceItem,
          Decidim::CommonNeed::CareBasket,
          Decidim::CommonNeed::CareBasketItem,
          Decidim::CommonNeed::Delivery,
          Decidim::CommonNeed::RouteStop,
          Decidim::CommonNeed::TimebankEntry,
          Decidim::CommonNeed::FederatedNode,
          Decidim::CommonNeed::InterNodeRequest,
          Decidim::Authorization
        ].each(&:clear_records!)
        Decidim::EventsManager.clear!
        Turbo::StreamsChannel.clear!
      end

      def define_lets!
        @group.all_lets.each do |name, block|
          define_singleton_method(name) do
            @memoized.fetch(name) { @memoized[name] = instance_eval(&block) }
          end
        end
      end

      def verify_spies!
        @spies.each(&:verify!)
      end
    end

    class Matcher
      def initialize(match_proc, failure_proc)
        @match_proc = match_proc
        @failure_proc = failure_proc
      end

      def matches?(actual)
        @match_proc.call(actual)
      end

      def failure_message(actual)
        @failure_proc.call(actual)
      end
    end

    class BeComparisonMatcher
      def >(other)
        Matcher.new(->(a) { a > other }, ->(a) { "expected #{a} > #{other}" })
      end

      def >=(other)
        Matcher.new(->(a) { a >= other }, ->(a) { "expected #{a} >= #{other}" })
      end

      def <(other)
        Matcher.new(->(a) { a < other }, ->(a) { "expected #{a} < #{other}" })
      end

      def <=(other)
        Matcher.new(->(a) { a <= other }, ->(a) { "expected #{a} <= #{other}" })
      end
    end

    class RaiseErrorMatcher
      def initialize(error_class, message_match = nil)
        @error_class = error_class
        @message_match = message_match
      end

      def matches?(block)
        block.call
        @failure = "expected #{@error_class} to be raised, but nothing was raised"
        false
      rescue Exception => e # rubocop:disable Lint/RescueException
        if e.is_a?(@error_class)
          if @message_match && !e.message.match?(@message_match)
            @failure = "expected #{@error_class} message #{e.message.inspect} to match #{@message_match.inspect}"
            false
          else
            true
          end
        else
          @failure = "expected #{@error_class}, got #{e.class}: #{e.message}"
          false
        end
      end

      def supports_negation_on_block?(block)
        block.call
        true
      rescue Exception => e # rubocop:disable Lint/RescueException
        @failure = "expected no error, got #{e.class}: #{e.message}"
        false
      end

      def failure_message(_actual)
        @failure || "expected #{@error_class}"
      end
    end

    class ChangeMatcher
      def initialize(receiver = nil, message = nil, &block)
        @eval_proc = block || -> { receiver.public_send(message) }
        @has_from = false
        @has_to = false
        @has_by = false
      end

      def from(val)
        @from_val = val
        @has_from = true
        self
      end

      def to(val)
        @to_val = val
        @has_to = true
        self
      end

      def by(delta)
        @by_delta = delta
        @has_by = true
        self
      end

      def matches?(block)
        before_val = @eval_proc.call
        block.call
        after_val = @eval_proc.call

        if @has_from && before_val != @from_val
          @failure = "expected initial value #{@from_val.inspect}, got #{before_val.inspect}"
          return false
        end
        if @has_to && after_val != @to_val
          @failure = "expected value to change to #{@to_val.inspect}, got #{after_val.inspect}"
          return false
        end
        if @has_by && (after_val - before_val) != @by_delta
          @failure = "expected change by #{@by_delta.inspect}, got #{after_val - before_val}"
          return false
        end

        before_val != after_val
      end

      def failure_message(_actual)
        @failure || "expected value to change"
      end
    end

    class ReceiveMatcher
      attr_reader :method_name

      def initialize(method_name)
        @method_name = method_name.to_sym
        @called = false
        @return_value = nil
      end

      def with(*expected_args)
        @expected_args = expected_args
        self
      end

      def and_return(val)
        @return_value = val
        self
      end

      def attach_to!(target, enforce_expectation: true)
        @target = target
        @enforce_expectation = enforce_expectation
        matcher = self
        ret = @return_value
        target.define_singleton_method(@method_name) do |*args, **_kwargs|
          matcher.record_call!(args)
          ret
        end
        true
      end

      def record_call!(args)
        @called = true
        @actual_args = args
      end

      def matches?(target)
        attach_to!(target, enforce_expectation: true)
      end

      def verify!
        return unless @enforce_expectation
        return if @called

        raise ExpectationNotMetError, "expected #{@target.inspect} to receive :#{@method_name}, but it was never called"
      end

      def failure_message(_actual)
        "expected target to receive :#{@method_name}"
      end
    end

    class AllowanceTarget
      def initialize(target)
        @target = target
      end

      def to(receive_matcher)
        receive_matcher.attach_to!(@target, enforce_expectation: false)
      end
    end

    class ExpectationTarget
      def initialize(actual, is_block: false)
        @actual = actual
        @is_block = is_block
      end

      def to(matcher)
        return if matcher.matches?(@actual)

        raise ExpectationNotMetError, matcher.failure_message(@actual)
      end

      def not_to(matcher)
        if @is_block && matcher.respond_to?(:supports_negation_on_block?)
          return if matcher.supports_negation_on_block?(@actual)

          raise ExpectationNotMetError, matcher.failure_message(@actual)
        end

        return unless matcher.matches?(@actual)

        raise ExpectationNotMetError, "expected #{@actual.inspect} not to match"
      end
      alias to_not not_to
    end

    # Capybara-compatible Session backed by PwaPortalController & PwaManifestController
    class CapybaraPageSession
      attr_reader :current_path, :body, :status_code, :response_headers

      def initialize
        @current_path = "/"
        @body = ""
        @status_code = 200
        @response_headers = {}
      end

      def visit(path)
        uri = URI.parse(path)
        @current_path = uri.path
        query_params = URI.decode_www_form(uri.query.to_s).to_h.transform_keys(&:to_sym)

        case @current_path
        when "/manifest.json"
          ctrl = Decidim::CommonNeed::PwaManifestController.new(query_params)
          @body = ctrl.manifest
          @response_headers = { "Content-Type" => "application/json" }
        when "/service-worker.js"
          ctrl = Decidim::CommonNeed::PwaManifestController.new(query_params)
          @body = ctrl.service_worker
          @response_headers = ctrl.response.headers
        else
          ctrl = Decidim::CommonNeed::PwaPortalController.new(query_params)
          ctrl.index
          template_path = File.join(ENGINE_ROOT, "app/views/decidim/common_need/pwa_portal/index.html.erb")
          @body = RenderContext.new(ctrl).render_erb(template_path)
          @response_headers = { "Content-Type" => "text/html; charset=utf-8" }
        end
        @status_code = 200
        self
      end

      def text
        @body.to_s
      end

      def has_css?(selector, text: nil)
        matched = if selector.start_with?("#")
                    id = selector.sub(/\A#/, "")
                    @body.include?("id=\"#{id}\"") || @body.include?("id='#{id}'")
                  elsif selector.start_with?(".")
                    cls = selector.sub(/\A\./, "").split(".").first
                    @body.include?(cls)
                  elsif selector.include?("[")
                    attr_expr = selector[/\[(.*?)\]/, 1].to_s.tr("'", '"')
                    @body.tr("'", '"').include?(attr_expr)
                  else
                    @body.include?("<#{selector}")
                  end
        matched && (text.nil? || @body.include?(text.to_s))
      end

      class RenderContext
        def initialize(controller)
          controller.instance_variables.each do |ivar|
            instance_variable_set(ivar, controller.instance_variable_get(ivar))
          end
        end

        def cell(name, model, options = {})
          klass_name = "#{name.split('/').map { |p| p.split('_').map(&:capitalize).join }.join('::')}Cell"
          klass = Object.const_get(klass_name)
          klass.new(model, options)
        end

        def raw(str)
          str.to_s
        end

        def j(str)
          str.to_s.gsub("'", "\\\\'").gsub('"', '\\"')
        end
        alias escape_javascript j

        def current_local_node_code
          Decidim::CommonNeed.local_node_code
        end

        def render_erb(path)
          ERB.new(File.read(path)).result(binding)
        end
      end
    end
  end

  def describe(*args, &block)
    RSpec.describe(*args, &block)
  end

  at_exit do
    RSpec.run_all! if $ERROR_INFO.nil?
  end
end
