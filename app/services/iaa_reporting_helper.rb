# frozen_string_literal: true

module IaaReportingHelper
  module_function

  IaaConfig = Struct.new(
    :gtc_number,   # ex LG123567
    :order_number, # ex 1
    :issuers,
    :start_date,
    :end_date,
    keyword_init: true,
  ) do
    # ex LG123567-0001
    def key
      IaaReportingHelper.key(gtc_number:, order_number:)
    end
  end

  PartnerConfig = Struct.new(
    :partner,
    :issuers,
    :start_date,
    :end_date,
    keyword_init: true,
  )

  def iaas
    sql = <<~SQL
      SELECT
        gtc.gtc_number,
        iaa_order.order_number,
        iaa_order.start_date,
        iaa_order.end_date,
        listagg(integration.issuer, ',') AS issuers
      FROM idp.iaa_gtcs gtc
      JOIN idp.iaa_orders iaa_order ON iaa_order.iaa_gtc_id = gtc.id
      JOIN idp.integration_usages iu ON iu.iaa_order_id = iaa_order.id
      JOIN idp.integrations integration ON integration.id = iu.integration_id
      GROUP BY gtc.gtc_number, iaa_order.order_number, iaa_order.start_date, iaa_order.end_date
      ORDER BY gtc.gtc_number, iaa_order.order_number
    SQL

    results = DataWarehouseApplicationRecord.connection.select_all(sql)
    results.map do |iaa|
      IaaConfig.new(
        gtc_number: iaa['gtc_number'],
        order_number: iaa['order_number'],
        issuers: parse_pg_array(iaa['issuers']),
        start_date: iaa['start_date'],
        end_date: iaa['end_date'],
      )
    end
  end

  # @return [Array<PartnerConfig>]
  def partner_accounts
    sql = <<~SQL
      SELECT
        partner_account.requesting_agency AS partner,
        listagg(sp.issuer, ',') AS issuers,
        MIN(iaa_order.start_date) AS start_date,
        MAX(iaa_order.end_date) AS end_date
      FROM idp.partner_accounts partner_account
      JOIN idp.integrations integration ON integration.partner_account_id = partner_account.id
      JOIN idp.service_providers sp ON sp.issuer = integration.issuer
      JOIN idp.integration_usages iu ON iu.integration_id = integration.id
      JOIN idp.iaa_orders iaa_order ON iaa_order.id = iu.iaa_order_id
      GROUP BY partner_account.requesting_agency
      ORDER BY partner_account.requesting_agency
    SQL

    results = DataWarehouseApplicationRecord.connection.select_all(sql)
    results.map do |partner|
      PartnerConfig.new(
        partner: partner['partner'],
        issuers: partner['issuers'].split(',').map(&:strip), # Convert string to array
        start_date: partner['start_date'],
        end_date: partner['end_date'],
      )
    end
  end

  def key(gtc_number:, order_number:)
    "#{gtc_number}-#{format('%04d', order_number)}"
  end

  def parse_pg_array(pg_array)
    pg_array[1..-2].split(',').map(&:strip)
  end
end
