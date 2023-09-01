# frozen_string_literal: true

require 'faraday'
require 'json'
require 'openssl'

module VolterraInspec
  # Implements a reusable client that authenticates to Volterra API via a PKCS#12 file and passphrase, or separate PEM
  # certificate and private key files. The client takes the same parametes and environment variables as the published
  # Terraform provider, and will raise an error on any response that is not 200 or 404.
  #
  # |Parameter|Environment|Description|
  # +---------+-----------+-----------+
  # |:api_p12_file|VOLT_API_P12_FILE|Path of the PKCS#12 file to use for authentication                                |
  # |             |VES_P12_PASSWORD |The passphrase to open PKCS#12 file                                               |
  # |:api_cert    |VOLT_API_CERT    |Path of the x509 PEM file to use for authentication                               |
  # |:api_key     |VOLT_API_KEY     |Path of the PEM private key file to use for authentication                        |
  # |:url         |VOLT_API_URL     |Base URL for your Volterra tenant API, e.g. https://MY_TENANT.ves.volterra.io/api |
  # |:timeout     |VOLT_API_TIMEOUT |Read timeout for API requests in go
  class ApiClient
    def initialize(params = {})
      @params = params
      @conn = Faraday.new(url: base, headers: { 'User-Agent': user_agent }, ssl: ssl, request: request) do |config|
        config.response :raise_error
      end
    end

    # Retrieves the Volterra resource from the specified path, returning a hash of values or nil for not found.
    # All other client exceptions will be allowed to propagate to caller.
    def fetch(resource, params = {})
      JSON.parse(@conn.get(resource, params).body, { symbolize_names: true }).fetch(:object)
    rescue Faraday::ResourceNotFound
      # Return nil for 404 instead of allowing exception to propagate
      nil
    end

    private

    # The base URL for Volterra API calls will be taken from options if provided, falling back to environment variable
    # then free tier URL.
    def base
      (@params[:url] || ENV.fetch('VOLT_API_URL', 'https://console.ves.volterra.io/api')).freeze
    end

    # The user-agent to embed in requests to Volterra API
    def user_agent
      'inspec-volterra/1.0.0'
    end

    # Determines the correct client certificate and key pair, and sets the required SSL parameters for requests to
    # Volterra API.
    def ssl
      cert, key = load_cert_key_from_pkcs12
      cert, key = load_cert_key_from_files unless cert && key
      raise StandardError, 'Unable to load Volterra client certificate and key' unless cert && key

      {
        client_cert: cert,
        client_key: key,
        min_version: OpenSSL::SSL::TLS1_2_VERSION,
        verify_mode: OpenSSL::SSL::VERIFY_PEER
      }.freeze
    end

    # Attempts to load a PKCS#12 file from params or environment, and a passphrase from the environment, returing the
    # client certificate and private key or a pair of nils.
    def load_cert_key_from_pkcs12
      api_p12_file = @params[:api_p12_file] || ENV.fetch('VOLT_API_P12_FILE', nil)
      api_p12_password = ENV.fetch('VES_P12_PASSWORD', nil)
      return [nil, nil] if api_p12_file.nil? || api_p12_file.empty? || api_p12_password.nil? || api_p12_password.empty?

      p12 = OpenSSL::PKCS12.new(File.read(api_p12_file), api_p12_password)
      [p12.certificate, p12.key]
    end

    # Attempts to load a PEM encoded X509 certificate and key from params or environment, returing them or a pair of
    # certificate and private key or nils.
    def load_cert_key_from_files
      api_cert = @params[:api_cert] || ENV.fetch('VOLT_API_CERT', nil)
      api_key = @params[:api_key] || ENV.fetch('VOLT_API_KEY', nil)
      return [nil, nil] if api_cert.nil? || api_cert.empty? || api_key.nil? || api_key.empty?

      [OpenSSL::X509::Certificate.new(File.read(api_cert)), OpenSSL::PKey.read(File.read(api_key))]
    end

    # Defines the Faraday request options that are common to all Volterra GET endpoints.
    def request
      {
        open_timeout: 5,
        read_timeout: read_timeout
      }.freeze
    end

    # Returns the timeout in seconds to use when reading from the Volterra API, either from an explicit parameter or the
    # environment, falling back to 20s if there is an error or the value is unknown.
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def read_timeout
      value = @params[:timeout] || ENV.fetch('VOLT_API_TIMEOUT')
      # Go duration parsing approach stolen from Tim Evans :)
      # See https://gist.github.com/tim-evans/d0ba1e8f05a55b76c49c
      value.scan(/([\d.-]+)((?:n|u|u{00b5 03bc}|m)s|s|m|h)/).reduce(0) do |total, parsed_duration|
        number, unit = parsed_duration
        total + case unit
                when 'ns'
                  number.to_i / 1_000_000_000
                when /(u|\u{00b5 03bc})s/
                  number.to_i / 1_000_000
                when 'ms'
                  number.to_i / 1_000
                when 's'
                  number.to_i
                when 'm'
                  number.to_i * 60
                when 'h'
                  number.to_i * 3_600
                end
      end
    rescue StandardError
      20
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength
  end
end
