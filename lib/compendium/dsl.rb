require 'collection_of'
require 'inheritable_attr'
require 'compendium/option'
require 'active_support/core_ext/class/attribute'

module Compendium
  module DSL
    def self.extended(klass)
      klass.inheritable_attr :queries, default: ::Collection[Query]
      klass.inheritable_attr :options, default: {}
    end

    def query(name, opts = {}, &block)
      define_query(name, opts, &block)
    end
    alias_method :chart, :query
    alias_method :data, :query

    def option(name, *args)
      opts = args.extract_options!
      type = args.shift

      if options[name]
        options[name].type = type if type
        options[name].merge!(opts)
      else
        options[name] = Compendium::Option.new(opts.merge(name: name, type: type))
      end
    end

    def metric(name, proc, opts = {})
      raise ArgumentError, 'through option must be specified for metric' unless opts.key?(:through)

      [opts.delete(:through)].flatten.each do |query|
        raise ArgumentError, "query #{query} is not defined" unless queries.key?(query)
        queries[query].add_metric(name, proc, opts)
      end
    end

    # Allow defined queries to be redefined by name, eg:
    # query :main_query
    # main_query { collect_records_here }
    def method_missing(name, *args, &block)
      if queries.keys.include?(name.to_sym)
        query = queries[name.to_sym]
        query.proc = block if block_given?
        query.options = args.extract_options!
        return query
      end

      super
    end

    def respond_to_missing?(name, *args)
      return true if queries.keys.include?(name)
      super
    end

  private

    def define_query(name, opts, type = Query, &block)
      name = name.to_sym
      query = type.new(name, opts, block)

      if opts.key?(:through)
        through = [opts[:through]].flatten

        through.each do |q|
          raise ArgumentError, "query #{q} is not defined" unless self.queries.include?(q.to_sym)
        end

        query.through = through
      end

      metrics[name] = opts[:metric] if opts.key?(:metric)
      queries << query
    end
  end
end