module Document
  module Searchable
    # TODO: use ActiveSupport::Concern

    def self.included(base)
      base.extend(ClassMethods)

      base.extend(Document::Search::Query)
      base.extend(Document::Search::Filter)
      base.extend(Document::Search::Facet)
      base.extend(Document::Search::Results)
    end

    module ClassMethods

      def search_by(params = {})
        format_result(*compose_search(params))
      end

      private

      def compose_search(params)
        page         = params[:page]         || 1
        per_page     = params[:per_page]     || 20
        query        = params[:query]        || Hash.new
        terms        = params[:filter]       || Hash.new
        facets       = params[:facets]       || @facets
        highlights   = params[:highlights]   || @highlights
        dependencies = params[:dependencies] || @dependencies
        options      = params[:options]      || {}
        sort         = params[:sort]
        order        = params[:order]

        options[:global_facets] ||= false

        prepare(terms, facets, dependencies)

        results = tire.search page: page, per_page: per_page do |index|
          if block_given?
            yield index, query, facets, highlights, dependencies, sort, order, options
          else
            search_query(index, query, options)
            search_filter(index, query, facets, options)
            search_facets(index, query, facets, options)
            search_sort(index, sort, order, options)
            search_highlights(index, query, highlights, options)
          end

          puts JSON.pretty_generate(index.to_hash) # debug
        end

        return facets, highlights, results
      end

      def prepare(terms, facets, dependencies)
        facets.each do |_, facet|
          facet.refresh!
        end

        terms.each do |name, values|
          facets[name].terms = values
        end

        # TODO: use dependencies
      end

      # TODO: figure out how to send hash insted of dsl to elastic from tire for search query
      def search_query(index, query, options)
        if query.any?

          index.query do |q|
            q.boolean do |bool|
              query.each do |field, values|
                field = analyzed_field(field)

                values = escape_query(values)

                bool.must {
                  string values,
                  default_field: field,
                  default_operator: :or,
                  analyze_wildcard: true
                }
              end
            end
          end
        end
      end

      def search_filter(index, query, facets, options)
        if query.any? || facets.any?
          filters = []

          filters.concat build_query(query)        if query.any?
          filters.concat build_filter(:or, facets) if facets.any?

          index.filter :and, filters if filters.any?
        end
      end

      def search_facets(index, query, facets, options)
        if facets.any?

          facets.each do |name, facet|
            facet_options = Hash.new

            # global facets
            facet_options[:global]       = options[:global_facets]
            facet_options[:facet_filter] = facet_filter(query.except(name), facets.except(name))
            facet_options[:size]         = facet.size

            build_facet(index, name, facet.field, facet, facet_options)

            # facets for selected values
            if query[name] || facets[name].terms.any?
              facet_options[:global]       = false
              facet_options[:facet_filter] = facet_filter(query, facets)
              facet_options[:size]         = facet.size

              build_facet(index, selected_field(name), facet.field, facet, facet_options)
            end
          end

        end
      end

      def search_sort(index, sort, order, options)
        field = not_analyzed_field(sort)

        if sort
          index.sort { by field, order || 'desc' }
        end
      end

      def search_highlights(index, query, highlights, options)
        options = highlights.find_all { |f| query.key?(f) }.map { |e| analyzed_field(e) }

        index.highlight(*options)
      end
    end
  end
end
