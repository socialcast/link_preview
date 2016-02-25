# Copyright (c) 2011 Erik Michaels-Ober, Wynn Netherland, et al.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# NOTE faraday-middleware is not compatible with faraday 0.9.0
# https://github.com/lostisland/faraday_middleware/pull/59
#
# Copied from https://github.com/lostisland/faraday_middleware
require 'faraday'
require 'set'

module Faraday
  # Public: Exception thrown when the maximum amount of requests is exceeded.
  class RedirectLimitReached < Faraday::Error::ClientError
    attr_reader :response

    def initialize(response)
      super "too many redirects; last one to: #{response['location']}"
      @response = response
    end
  end

  # Public: Follow HTTP 301, 302, 303, and 307 redirects.
  #
  # For HTTP 301, 302, and 303, the original GET, POST, PUT, DELETE, or PATCH
  # request gets converted into a GET. With `:standards_compliant => true`,
  # however, the HTTP method after 301/302 remains unchanged. This allows you
  # to opt into HTTP/1.1 compliance and act unlike the major web browsers.
  #
  # This middleware currently only works with synchronous requests; i.e. it
  # doesn't support parallelism.
  class FollowRedirects < Faraday::Middleware
    # HTTP methods for which 30x redirects can be followed
    ALLOWED_METHODS = Set.new [:head, :options, :get, :post, :put, :patch, :delete]
    # HTTP redirect status codes that this middleware implements
    REDIRECT_CODES  = Set.new [301, 302, 303, 307]
    # Keys in env hash which will get cleared between requests
    ENV_TO_CLEAR    = Set.new [:status, :response, :response_headers]

    # Default value for max redirects followed
    FOLLOW_LIMIT = 3

    # Public: Initialize the middleware.
    #
    # options - An options Hash (default: {}):
    #           :limit               - A Numeric redirect limit (default: 3)
    #           :standards_compliant - A Boolean indicating whether to respect
    #                                  the HTTP spec when following 301/302
    #                                  (default: false)
    #           :cookies             - An Array of Strings (e.g.
    #                                  ['cookie1', 'cookie2']) to choose
    #                                  cookies to be kept, or :all to keep
    #                                  all cookies (default: []).
    def initialize(app, options = {})
      super(app)
      @options = options

      @convert_to_get = Set.new [303]
      @convert_to_get << 301 << 302 unless standards_compliant?
    end

    def call(env)
      perform_with_redirection(env, follow_limit)
    end

    private

    def convert_to_get?(response)
      ![:head, :options].include?(response.env[:method]) &&
        @convert_to_get.include?(response.status)
    end

    def perform_with_redirection(env, follows)
      request_body = env[:body]
      response = @app.call(env)

      response.on_complete do |response_env|
        if follow_redirect?(response_env, response)
          raise RedirectLimitReached, response if follows.zero?
          response = perform_with_redirection(update_env(response_env, request_body, response), follows - 1)
        end
      end
      response
    end

    def update_env(env, request_body, response)
      env[:url] += response['location']
      if @options[:cookies]
        cookies = keep_cookies(env)
        env[:request_headers][:cookies] = cookies unless cookies.nil?
      end

      if convert_to_get?(response)
        env[:method] = :get
        env[:body] = nil
      else
        env[:body] = request_body
      end

      ENV_TO_CLEAR.each { |key| env.delete key }

      env
    end

    def follow_redirect?(env, response)
      ALLOWED_METHODS.include?(env[:method]) &&
        REDIRECT_CODES.include?(response.status)
    end

    def follow_limit
      @options.fetch(:limit, FOLLOW_LIMIT)
    end

    def keep_cookies(env)
      cookies = @options.fetch(:cookies, [])
      response_cookies = env[:response_headers][:cookies]
      cookies == :all ? response_cookies : selected_request_cookies(response_cookies)
    end

    def selected_request_cookies(cookies)
      selected_cookies(cookies)[0...-1]
    end

    def selected_cookies(cookies)
      ''.tap do |cookie_string|
        @options[:cookies].each do |cookie|
          string = /#{cookie}=?[^;]*/.match(cookies)[0] + ';'
          cookie_string << string
        end
      end
    end

    def standards_compliant?
      @options.fetch(:standards_compliant, false)
    end
  end
end
