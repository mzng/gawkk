require 'action_controller'

module ActionController
  module Routing
    class RouteSet
      def extract_request_environment(request)
        { :method => request.method, :host => request.host, :subdomains => request.subdomains }
      end
    end

    class Route
      def recognition_conditions
        result = ["(match = #{Regexp.new(recognition_pattern).inspect}.match(path))"]
        result << "conditions[:method] === env[:method]" if conditions[:method]
        result << "conditions[:hosts].include?(env[:host])" if conditions[:hosts]
        result << "env[:subdomains].include?(conditions[:subdomain])" if conditions[:subdomain]
        result << "env[:subdomains].size == BASE_URL_SIZE || (env[:subdomains].size == BASE_URL_SIZE + 1 && env[:subdomains].include?('www'))" if conditions[:root_only]
        result
      end
    end
  end
end
