# encoding: utf-8

module JusticeGovSk
  module Requests
    class ListRequest
      attr_accessor :page,
                    :per_page
      
      attr_reader :data
      
      def headers
        {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.3', 
          'Accept-Encoding' => 'gzip,deflate,sdch',
          'Accept-Language' => 'en-US,en;q=0.8',
          'Cache-Control' => 'max-age=0',
          'Connection' => 'keep-alive',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Host' => 'www.justice.gov.sk',
          'Origin' => 'http://www.justice.gov.sk',
          'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.94 Safari/537.4'
        }
      end 
      
      def data
        @data ||= File.read data_path
      end

      def data_path
        name = self.class.name

        File.join Rails.root, 'lib', 'assets', "#{name.underscore}.data"
      end

      def page=(value)
        data.gsub!(/cmbAGVPager=\d+&/, "cmbAGVPager=#{value}&")
        
        # TODO rm
        data.match /cmbAGVPager=\d+/ do |m|
          puts "XXXXXXXXX #{m}"
        end
      end

      def per_page=(value)
        data.gsub!(/cmbAGVCountOnPage=\d+&/, "cmbAGVCountOnPage=#{value}&")
      end
    end
  end
end
