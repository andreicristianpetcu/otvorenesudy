# encoding: utf-8

module JusticeGovSk
  module Parser
    class CriminalHearing < JusticeGovSk::Parser::Hearing
      def type(document)
        'Trestné'
      end
      
      def defendants(document)
        find_rows_by_group 'defendants', document, 'Obžalovaní' do |divs|
          map  = {}
          name = nil

          divs.each do |div|
            if div[:class] == 'popiska'
              name = JusticeGovSk::Helpers::NormalizeHelper.punctuation(div.text)
              map[name] = []
            elsif div[:class] == 'hodnota'
              value = accusation(div.text)
              
              map[name] << value unless value.blank? 
            end
          end

          map   
        end
      end
      
      private
      
      def accusation(value)
        value.strip.gsub(/^-?\s*/, '').strip.squeeze(' ')
      end
    end
  end
end
