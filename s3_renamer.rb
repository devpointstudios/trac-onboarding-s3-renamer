require 'dotenv/load'
require 'aws-sdk'
require 'pry'

puts 'Org Id:'
ORG_ID = gets.strip
puts 'Cycle Id:'
CYCLE_ID = gets.strip

S3 = Aws::S3::Resource.new(
  credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"]),
  region: ENV["AWS_REGION"]
)

CLIENT = S3.client
BUCKET = S3.bucket(ENV["AWS_BUCKET"])

companies = CLIENT.list_objects({
  prefix: "orgainzations/#{ORG_ID}/companies/",
  delimiter: '/',
  bucket: ENV["AWS_BUCKET"],
  encoding_type: 'url'
})['common_prefixes']

companies.each do |company|
  puts "Renaming Files For: #{company.prefix}"
  company_files = CLIENT.list_objects({
    prefix: "#{company.prefix}cycles/#{CYCLE_ID}/",
    delimiter: '/',
    bucket: ENV["AWS_BUCKET"],
    encoding_type: 'url'
  })['contents']

  if company_files.any?
    company_files.each do |file|
      begin
        obj = BUCKET.object(file.key)
        obj.move_to("#{ENV['AWS_BUCKET']}/#{file.key.split('.').first}.pdf", acl:'public-read')
        puts "Successfully Renamed File: #{file.key}"
      rescue => e
        "Error Renaming File: #{e}"
        next
      end
    end
  else
    puts "No Files Found For #{company.prefix}"
  end
end
