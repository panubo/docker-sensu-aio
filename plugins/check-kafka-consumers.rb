#! /usr/bin/env ruby
#
#   check-kafka-consumers
#
# DESCRIPTION:
# Connect to a burrow instance and pull statuses for all consumers on
# all clusters monitored by burrow.
#
# PARAMETERS:
# -u URL -- URL burrow is listening on (i.e., http://burrow.com:8000/endpoint)
#
# RETURNS:
# - CRITICAL if any consumer is STOP, ERR or STALL
# - WARNING if a consumer is WARN (i.e., falling behind)
# - UNKNOWN if NOTFOUND
# - OK otherwise
#

# From: https://github.com/Jana-Mobile/sensu-plugins/blob/master/burrow/check-kafka-consumers.rb
# LICENSE MIT

require 'sensu-plugin/check/cli'
require 'net/http'
require 'json'

class CheckKafkaConsumers  < Sensu::Plugin::Check::CLI

  ERROR_CODES = {
      'NOTFOUND' => :unknown,
      'OK' => :ok,
      'WARN' => :warn,
      'ERR' => :critical,
      'STOP' => :critical,
      'STALL' => :critical,
      'REWIND' => :ok
  }
  ERROR_CODES.default = :unknown

  option :burrow_url,
         description: 'Base burrow url',
         short: '-u URL',
         long: '--url URL'

  def check_consumer(cluster, consumer, http)
    consumers_url = "#{config[:base_uri]}/v3/kafka/#{cluster}/consumer/#{consumer}/status"
    req = Net::HTTP::Get.new(consumers_url)
    res = http.request(req)

    consumer_status = JSON.parse(res.body)
    return consumer_status['status']['status']
  end

  def check_cluster(cluster, http)
    consumers_url = "#{config[:base_uri]}/v3/kafka/#{cluster}/consumer"
    req = Net::HTTP::Get.new(consumers_url)
    res = http.request(req)

    consumers = JSON.parse(res.body)
    if consumers['error']
      return false
    end

    consumer_results = {}
    consumers['consumers'].each do|consumer|
      result = check_consumer(cluster, consumer, http)
      consumer_results[consumer] = result
    end

    return consumer_results
  end

  def run
    uri = URI.parse(config[:burrow_url])
    config[:host] = uri.host
    config[:port] = uri.port
    config[:request_uri] = uri.request_uri
    config[:ssl] = uri.scheme == 'https'

    http = Net::HTTP.new(config[:host], config[:port], nil, nil)
    clusters_url = "#{config[:base_uri]}/v3/kafka"
    req =  Net::HTTP::Get.new(clusters_url)
    res = http.request(req)

    # get the set of clusters monitored by burrow
    clusters = JSON.parse(res.body)['clusters']
    cluster_results = {}

    # pull down the status of all consumers in the clusters
    aggregates = {}
    aggregates.default = 0

    clusters.each do|cluster|
      consumer_results = check_cluster(cluster, http)
      consumer_results.each do |_, result|
        aggregates[ERROR_CODES[result]] += 1
      end

      cluster_results[cluster] = consumer_results
    end

    pretty_results = JSON.pretty_generate(cluster_results)
    if aggregates[:critical] > 0
      critical("Cluster consumer check failed: #{pretty_results}")
    elsif aggregates[:warn] > 0
      warning("Cluster consumer check failed: #{pretty_results}")
    elsif aggregates[:unknown] > 0
      unknown("Cluster consumer check failed: #{pretty_results}")
    else
      ok("Cluster consumer check ok: #{pretty_results}")
    end

  end
end
