#!/usr/bin/env ruby
# frozen_string_literal: true

require 'httparty'
require 'date'
require 'optparse'
require 'time'

# Simplified PagerDuty on-call summarizer
class PagerDutyOnCallTime
  API_BASE      = 'https://api.pagerduty.com'.freeze
  API_VERSION   = 'application/vnd.pagerduty+json;version=2'.freeze
  DEFAULT_LIMIT = 100

  def initialize(token:, time_zone: nil)
    @headers = {
      'Accept'        => API_VERSION,
      'Content-Type'  => 'application/json',
      'Authorization' => "Token token=#{token}"
    }
    @time_zone = time_zone
  end

  # List all escalation policies (ID — Name)
  def list_policies
    params = { limit: DEFAULT_LIMIT, total: true }
    params[:time_zone] = @time_zone if @time_zone
    response = HTTParty.get(
      "#{API_BASE}/escalation_policies",
      headers: @headers,
      query: params
    )

    unless response.code == 200
      warn "❌ Failed to fetch policies: #{response.code} #{response.message}";
      warn "Body: #{response.body}";
      exit 1
    end

    policies = response.parsed_response['escalation_policies'] || []
    puts "Escalation Policy IDs and Names:"
    policies.each { |p| puts "#{p['id']} — #{p['summary']}" }
  end

  # Fetch oncalls with proper pagination and total count
  def fetch_oncalls(since: nil, until_time: nil, user_ids: [], policy_ids: [], earliest: false)
    params = {
      limit:    DEFAULT_LIMIT,
      total:    true,
      earliest: earliest
    }
    params[:since]     = since.iso8601      if since
    params[:until]     = until_time.iso8601 if until_time
    params[:time_zone] = @time_zone         if @time_zone
    params[:user_ids]               = user_ids   if user_ids.any?
    params[:escalation_policy_ids] = policy_ids if policy_ids.any?

    all_oncalls = []
    offset = 0
    loop do
      params[:offset] = offset
      response = HTTParty.get(
        "#{API_BASE}/oncalls",
        headers: @headers,
        query:   params
      )

      unless response.code == 200
        warn "❌ API Error #{response.code}: #{response.message}";
        warn "Body: #{response.body}";
        exit 1
      end

      data = response.parsed_response
      all_oncalls.concat(data['oncalls'] || [])
      total = data['total'] || all_oncalls.size
      break if all_oncalls.size >= total
      offset += DEFAULT_LIMIT
    end

    all_oncalls
  end

  # Summarize on-call hours per user
  def summarize(oncalls)
    user_hours = Hash.new(0.0)
    oncalls.each do |o|
      next unless o['start'] && o['end']
      start_t = Time.parse(o['start'])
      end_t   = Time.parse(o['end'])
      key     = "#{o.dig('user','summary')} (#{o.dig('user','id')})"
      user_hours[key] += (end_t - start_t) / 3600.0
    end
    user_hours.sort_by { |_, hrs| -hrs }
  end

  # Display only summary (no detailed list)
  def display_summary(sorted_times)
    puts "\nOn-Call Time Summary"
    puts '-' * 60
    puts "% -40s %10s" % ['User', 'Hours']
    puts '-' * 60
    sorted_times.each do |user, hrs|
      puts "% -40s %10.2f" % [user, hrs]
    end
  end
end

# --- CLI ---
options = { user_ids: [], policy_ids: [], earliest: false }
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"
  opts.on('--token TOKEN',     'PagerDuty API token')     { |t| options[:token]     = t }
  opts.on('--since DATE',      'Start date YYYY-MM-DD')   { |d| options[:since]     = Date.parse(d) }
  opts.on('--until DATE',      'End date YYYY-MM-DD')     { |d| options[:until]     = Date.parse(d) }
  opts.on('--user ID',         'Filter by user (multi)')  { |u| options[:user_ids]   << u }
  opts.on('--policy ID',       'Filter by policy (multi)'){ |p| options[:policy_ids] << p }
  opts.on('--earliest',        'Earliest on-call only')   { options[:earliest]     = true }
  opts.on('--tz ZONE',         'Time zone (e.g. Europe/Amsterdam)') { |z| options[:tz] = z }
  opts.on('--list-policies',   'List escalation policy IDs and names') { options[:list_policies] = true }
  opts.on('-h', '--help',      'Help message')            { puts opts; exit }
end.parse!

token = options[:token] || ENV['PAGERDUTY_API_TOKEN']
abort "❌ PagerDuty API token required" unless token

client = PagerDutyOnCallTime.new(token: token, time_zone: options[:tz])

# If listing policies, do that and exit
if options[:list_policies]
  client.list_policies
  exit
end

# Fetch and display summary
oncalls = client.fetch_oncalls(
  since:      options[:since],
  until_time: options[:until],
  user_ids:   options[:user_ids],
  policy_ids: options[:policy_ids],
  earliest:   options[:earliest]
)
sorted = client.summarize(oncalls)
client.display_summary(sorted)
