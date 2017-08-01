#!/usr/bin/env ruby

require 'sinatra'
require 'net/http'
require 'json'
require 'hash_dot'

Hash.use_dot_syntax = true

def fetch_json(url)
  uri = URI("#{ARGV[0]}/#{url}")
  response = Net::HTTP.get(uri)
  return JSON.parse(response)
end

def title_for_build(build, heading)
  timestamp = Time.at(build.timestamp/1000)
  "<#{heading}>#{build.displayName} - #{timestamp}</#{heading}>"
end

def artifacts_for_build(build)
  output = "<p>"
  build.artifacts.each do |artifact|
    output += "<a href=\"#{build.url}artifact/#{artifact.relativePath}\">#{artifact.relativePath}</a><br>"
  end
  output += "</p>"

  return output
end

def changeset_for_build(build)
  output = "<p>"
  build.changeSet.items.each do |change_set|
    output += "<i>#{change_set.comment}<br><a href=\"mailto:#{change_set.authorEmail}\">#{change_set.author.fullName}</a> - #{change_set.date}<br></i>"
  end
  output += "</p>"

  return output
end

def output_for_build(job_name, build_name, heading)
  output = ""

  build = fetch_json("job/Android/job/#{job_name}/#{build_name}/api/json")

  if !build.building && build.result == "SUCCESS" then
    output += title_for_build(build, heading)
    output += artifacts_for_build(build)
    output += changeset_for_build(build)
    output += "<hr>"
  end

  return output
end

def output_for_last_successful_build(job_name)
  return output_for_build(job_name, "lastSuccessfulBuild", "h3")
end

get '/' do
  projects = fetch_json("job/android/api/json")

  output = "<h1>All Jobs</h1>"
  projects.jobs.each do |job|
    output += "<h2><a href=\"artifacts/#{job.name}\">#{job.name}</a></h2>"
    output += output_for_last_successful_build(job.name)
  end

  "#{output}"
end

get '/artifacts/:job_name' do |job_name|

  output = "<h1>Build History</h1>"

  job = fetch_json("job/Android/job/#{job_name}/api/json")
  job.builds.each do |build_details|
    output += output_for_build(job_name, build_details.number, "h2")
  end

  "#{output}"
end
