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
        result
      end
    end
  end
end
