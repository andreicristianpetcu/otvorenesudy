module JusticeGovSk
  module Requests
    module URL
      def self.base
        'http://www.justice.gov.sk'
      end

      def self.headers
        {
          'Accept'          => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language' => 'en-US,en;q=0.5',
          'Accept-Encoding' => 'gzip, deflate',
          'Cache-Control'   => 'max-age=0',
          'DNT'             => '1',
          'Connection'      => 'keep-alive',
          'Cookie'          => '__utma=161066278.1871589972.1351081154.1352917575.1352943059.48; __utmz=161066278.1351118484.7.3.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=mssr; ASP.NET_SessionId=t4koyt45ztxjll55ls3cr5z0; __utmc=161066278; __utmb=161066278.1.10.1352943059',
          'Host'            => 'www.justice.gov.sk',
          'User-Agent'      => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0'
        }
      end
      
      def self.url_to_path(url, ext = nil)
        uri  = URI.parse(url)
        path = uri.path
        
        path.gsub!(/Stranky\/Sudy/i,              '')
        path.gsub!(/Stranky\/Pojednavania/i,      '')
        path.gsub!(/Stranky\/Sudne-rozhodnutia/i, '')
        
        path.gsub!(/\/SudDetail/i,              '')
        path.gsub!(/PojednavanieDetail/i,       'civil-hearing')
        path.gsub!(/PojednavanieTrestDetail/i,  'criminal-hearing')
        path.gsub!(/PojednavanieSpecDetail/i,   'special-hearing')
        path.gsub!(/Sudne-rozhodnutie-detail/i, 'decree')

        path.gsub!(/\//, '')
        
        path.downcase!
        
        path = "#{path}?#{uri.query}" unless uri.query.nil?
        "#{path}.#{ext || :html}"
      end
      
      def self.url_to_path_lambda(ext = nil)
        lambda { |url| url_to_path(url, ext) }
      end
    end
  end
end