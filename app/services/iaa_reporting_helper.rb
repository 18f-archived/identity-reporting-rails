# frozen_string_literal: true

module IaaReportingHelper
  module_function

  def key(gtc_number:, order_number:)
    "#{gtc_number}-#{format('%04d', order_number)}"
  end
end
