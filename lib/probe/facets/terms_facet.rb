class Probe::Facets
  class TermsFacet < Probe::Facets::Facet
    include Probe::Search::Query

    attr_accessor :suggest_term,
                  :script

    def build(name, options)
      options = prepare_build(options)

      options.merge! terms: {
        field: not_analyzed_field(field),
        size:  size
      }

      yield options[:terms] if block_given?

      { name => options }
    end

    def build_filter
      filter = terms.map do |value|
        if value == missing_facet_name
          { missing: { field: not_analyzed_field(field), existence: true }}
        else
          { term: { not_analyzed_field(field) => value }}
        end
      end

      { filter_type => filter }
    end

    def build_query
      build_query_from(field, "#{suggest_term}*", default_operator: :and) if suggest_term.present?
    end

    def build_suggest_facet(index, options)
      build(index, name, options) do |f, facet_options|
        facet_options.merge! script.build if script
      end
    end

    private

    def populate_facets(results)
      values = results['terms'].map do |term|
        value = term['term']

        params        = create_result_params(value)
        add_params    = create_result_add_params(value)
        remove_params = create_result_remove_params(value)

        Result.new(value, term['count'], params, add_params, remove_params)
      end

      if results['missing'] > 0
        params        = create_result_params(missing_facet_name)
        add_params    = create_result_add_params(missing_facet_name)
        remove_params = create_result_remove_params(missing_facet_name)

        values << Result.new(missing_facet_name, results['missing'], params, add_params, remove_params)
      end

      values
    end

    class Result < Facet::Result
      def missing
        value == 'missing'
      end

      alias :missing? :missing
    end
  end
end
