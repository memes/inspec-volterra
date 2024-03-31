# frozen_string_literal: true

module VolterraInspec
  # Represents the common reference format used when one Volterra resource needs to associate with another Volterra
  # resource.
  class Reference
    attr_reader :name, :namespace, :tenant, :kind, :uid

    def initialize(data)
      @name = data.fetch(:name).freeze
      @namespace = data.fetch(:namespace).freeze
      @tenant = data.fetch(:tenant).freeze
      @kind = data.fetch(:kind, nil).freeze
      @uid = data.fetch(:uid, nil).freeze
    end

    def to_s
      "Reference #{@tenant}/#{@namespace}/#{@name}>"
    end
  end
end
