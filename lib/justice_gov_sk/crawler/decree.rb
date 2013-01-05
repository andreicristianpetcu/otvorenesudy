# TODO consider reseting matched judges, i.e. judgements when updating 

module JusticeGovSk
  class Crawler
    class Decree < JusticeGovSk::Crawler
      include JusticeGovSk::Helper::JudgeMatcher
      include JusticeGovSk::Helper::ProceedingSupplier
      
      attr_accessor :form_code
      
      def initialize(options = {})
        super(options)
        
        @form_code = options[:decree_form]
      end
      
      protected
      
      def process(request)
        super do
          uri = JusticeGovSk::Request.uri(request)
          
          @decree = decree_by_uri_factory.find_or_create(uri)
          
          @decree.uri  = uri
          @decree.text = fulltext(uri)
  
          @decree.case_number = @parser.case_number(@document)
          @decree.file_number = @parser.file_number(@document)
          @decree.date        = @parser.date(@document)
          @decree.ecli        = @parser.ecli(@document)
          
          supply_proceeding_for @decree
          
          court
          judge
          
          form
          nature
          
          legislation_area
          legislation_subarea
          
          legislations

          @decree          
        end
      end
      
      def fulltext(uri)
        request = inject JusticeGovSk::Request, implementation: Decree, suffix: :Document
        agent   = inject JusticeGovSk::Agent,   implementation: Decree, suffix: :Document
        
        request.url = uri

        agent.download(request)
        
        path = agent.storage.fullpath(agent.uri_to_path uri)
        
        print "Extracting text ... "
        
        text = Core::TextExtractor.new.extract(path)
        
        puts "done (#{text.length} chars)"
        
        text
      end
      
      def court
        name = @parser.court(@document)
        
        @decree.court = court_by_name_factory.find(name) unless name.nil?
      end
      
      def judge
        name = @parser.judge(@document)
        
        unless name.nil?
          match_judges_by(name) do |similarity, judge|
            judgement(judge, similarity, name)
          end
        end
      end
      
      def form
        raise "Decree form code not set" if @form_code.nil?
        
        @decree.form = decree_form_by_code_factory.find(@form_code)
        
        raise "Decree form not found" if @decree.form.nil?
      end
      
      def nature
        value = @parser.nature(@document)
        
        unless value.nil?
          nature = decree_nature_by_value_factory.find_or_create(value)
          
          nature.value = value
          
          @persistor.persist(nature) if nature.id.nil?
          
          @decree.nature = nature          
        end
      end
        
      def legislation_area
        value = @parser.legislation_area(@document)
        
        unless value.nil?
          legislation_area = legislation_area_by_value_factory.find_or_create(value)
          
          legislation_area.value = value
          
          @persistor.persist(legislation_area) if legislation_area.id.nil?
          
          @decree.legislation_area = legislation_area          
        end
      end
      
      def legislation_subarea
        value = @parser.legislation_subarea(@document)
        
        unless value.nil?
          legislation_subarea = legislation_subarea_by_value_factory.find_or_create(value)

          legislation_area(document) if @decree.legislation_area.nil?
          
          legislation_subarea.area  = @decree.legislation_area
          legislation_subarea.value = value
          
          @persistor.persist(legislation_subarea) if legislation_subarea.id.nil?
          
          @decree.legislation_subarea = legislation_subarea          
        end
      end
        
      def legislations
        list = @parser.legislations(@document)
    
        unless list.blank?
          puts "Processing #{pluralize list.count, 'legislation'}."
          
          list.each do |item|
            identifiers = @parser.legislation(item)
            
            unless identifiers.empty?
              value = identifiers[:value]
              
              legislation = legislation_by_value_factory.find_or_create(value)
              
              legislation.value             = value
              legislation.value_unprocessed = item
              
              legislation.number    = identifiers[:number] 
              legislation.year      = identifiers[:year]
              legislation.name      = identifiers[:name]
              legislation.paragraph = identifiers[:paragraph]
              legislation.section   = identifiers[:section]
              legislation.letter    = identifiers[:letter]
              
              @persistor.persist(legislation) if legislation.id.nil?
              
              legislation_usage(legislation)
            end
          end
        end
      end
      
      private
      
      def judgement(judge, similarity, name)
        judgement = judgement_by_judge_id_and_decree_id_factory.find_or_create(judge.id, @decree.id)
        
        judgement.judge                  = judge
        judgement.judge_name_similarity  = similarity
        judgement.judge_name_unprocessed = name[:unprocessed]

        judgement.decree = @decree
        
        @persistor.persist(judgement) if judgement.id.nil?
      end
      
      def legislation_usage(legislation)
        legislation_usage = legislation_usage_by_legislation_id_and_decree_id_factory.find_or_create(legislation.id, @decree.id)
        
        legislation_usage.legislation = legislation
        legislation_usage.decree      = @decree
        
        @persistor.persist(legislation_usage) if legislation_usage.id.nil?
      end
    end
  end
end
