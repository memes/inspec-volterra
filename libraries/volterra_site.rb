# frozen_string_literal: true

require 'inspec/resource'
require 'volterra/api_client'
require 'volterra/collections'
require 'volterra/metadata'
require 'volterra/parsers'
require 'volterra/reference'
require 'volterra/system_metadata'

# Implements a resource to verify properties of a Volterra Site as described at https://docs.cloud.f5.com/docs/api/site.
class VolterraSite < Inspec.resource(1)
  name 'volterra_site'
  desc <<-_DESCRIPTION_
  Doo
  _DESCRIPTION_
  example <<-_EXAMPLE_
  describe volterra_site(name: 'my-volterra-site', namespace: 'system') do
    it { should exist }
    # All fields in spec are exposed as properties
    its('ce_site_mode') { should cmp 'CE_SITE_MODE_INGRESS_EGRESS_GW' }
    its('connected_re.count') { should eq 2 }
    # Metadata fields are exposed through the metadata property
    its('metadata.description') { should cmp 'My testing site' }
  end
  _EXAMPLE_
  supports platform: 'os'

  SIMPLE_PROPERTIES = %i[address ce_site_mode desired_pool_count global_access_k8s_enabled ipsec_ssl_nodes_fqdn
                         local_access_k8s_enabled multus_enabled operating_system_version region site_state site_subtype
                         site_to_site_network_type site_type tunnel_dead_timeout tunnel_type vip_vrrp_mode vm_enabled
                         volterra_software_overide volterra_software_version].freeze
  IPADDRESS_PROPERTIES = %i[bgp_peer_address bgp_router_id inside_nameserver inside_vip outside_nameserver
                            outside_vip site_to_site_tunnel_ip].freeze
  REFERENCES_PROPERTIES = %i[connected_re connected_re_for_config].freeze
  EMPTY_PROPERTIES = %i[default_underlay_network].freeze
  attr_reader(:metadata, :system_metadata, :ares_list, :coordinates, :vip_params_per_az, *SIMPLE_PROPERTIES,
              *IPADDRESS_PROPERTIES, *REFERENCES_PROPERTIES, *EMPTY_PROPERTIES)

  # rubocop: disable Lint/MissingSuper
  def initialize(params = {})
    @name = params.fetch(:name)
    @namespace = params.fetch(:namespace, 'system')
    data = VolterraInspec::ApiClient.new(params).fetch(path)
    parse(data) unless data.nil?
  end
  # rubocop: enable Lint/MissingSuper

  def resource_id
    "#{@namespace}/sites/#{@name}"
  end

  def to_s
    "Site #{@namespace}/#{@name}"
  end

  def exists?
    !@metadata.nil?
  end

  private

  def path
    "config/namespaces/#{@namespace}/sites/#{@name}"
  end

  # TODO: @memes - revisit
  # rubocop:todo Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength
  def parse(data)
    data.each do |property, value|
      case property
      when :metadata
        @metadata = VolterraInspec::Metadata.new(value)
      when :system_metadata
        @system_metadata = VolterraInspec::SystemMetadata.new(value)
      when :spec
        value.fetch(:gc_spec, {}).each do |property, value|
          if SIMPLE_PROPERTIES.include?(property)
            instance_variable_set("@#{property}", if value.is_a?(Array)
                                                    VolterraInspec.parse_array(value, value[0].class)
                                                  elsif value.is_a?(Hash)
                                                    VolterraInspec::LookupHash.create(value).freeze
                                                  else
                                                    value.freeze
                                                  end)
          elsif IPADDRESS_PROPERTIES.include?(property)
            instance_variable_set("@#{property}", VolterraInspec.parse_ipaddress(value).freeze)
          elsif REFERENCES_PROPERTIES.include?(property)
            instance_variable_set("@#{property}", VolterraInspec.parse_array(value, VolterraInspec::Reference).freeze)
          elsif EMPTY_PROPERTIES.include?(property)
            instance_variable_set("@#{property}", VolterraInspec.parse_empty_object(value).freeze)
          elsif property == :ares_list
            @ares_list = VolterraInspec.parse_array(value, VolterraSite::ServiceParameters).freeze
          elsif property == :coordinates
            @coordinates = VolterraSite::Coordinates.new(value).freeze
          elsif property == :vip_params_per_az
            @vip_params_per_az = VolterraInspec.parse_array(value, VolterraSite::VipParams)
          else
            puts "Unknown spec property when parsing Site: #{property} => #{value}"
          end
        end
      else
        puts "Unknown property when parsing Site: #{property} => #{value}"
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength

  # Volterra site service parameters.
  class ServiceParameters
    attr_reader :ctype, :url

    def initialize(data)
      @ctype = data.fetch(:ctype, nil)
      @url = data.fetch(:url, nil)
    end

    def to_s
      "ServiceParameters #{@url} (#{@ctype})"
    end
  end

  # Volterra site coordinates.
  class Coordinates
    attr_reader :latitude, :longitude

    def initialize(data)
      @latitude, @longitude = parse(data)
    end

    def to_s
      "Coordinates #{@latitude}, #{@longitude}"
    end

    private

    def parse(data)
      return [nil, nil] if data.nil? || data.empty?

      [data.fetch(:latitude, nil), data.fetch(:longitude, nil)]
    end
  end

  # Volterra site VIP addresses.
  class VipParams
    attr_reader :az_name, :inside_vip, :inside_vip_cname, :outside_vip, :outside_vip_cname

    def initialize(data)
      @az_name = data.fetch(:az_name, nil).freeze
      @inside_vip = data.fetch(:inside_vip, []).map { |v| VolterraInspec.parse_ipaddress(v).freeze }
      @inside_vip_cname = data.fetch(:inside_vip_cname, nil)
      @outside_vip = data.fetch(:outside_vip, []).map { |v| VolterraInspec.parse_ipaddress(v).freeze }
      @outside_vip_cname = data.fetch(:outside_vip_cname, nil)
    end

    def to_s
      "VipParams #{@az_name}"
    end
  end
end
