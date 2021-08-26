require 'open-uri'
require 'nokogiri'
require 'pp'
require_relative 'dynamo_db'


class PropertyParser
  include DynamoDB

  DEFAULT_S3_PATH = 'https://s3.amazonaws.com/abodo-misc/sample_abodo_feed.xml'
  STATES = %w[wi wisconsin] 
  CITY = 'madison'
  PROPERTY_ID_PATH = './PropertyID/Identification/@IDValue'
  CITY_PATH = './PropertyID/Address/City'
  STATE_PATH = './PropertyID/Address/State'
  NAME_PATH = './PropertyID/MarketingName'
  EMAIL_PATH = './PropertyID/Email'
  BEDROOM_PATH = './Floorplan/Room'
  PRIMARY_ATTRIBUTES = %w[name property_id]

  def initialize(url=DEFAULT_S3_PATH)
    @url = url
  end

  def parse
    xml_doc = parse_xml(text_from_url)
    properties = process_children(xml_doc.root)
    pp properties
    add_items(properties, 'properties', PRIMARY_ATTRIBUTES)
    properties
  end

  private 

  def process_children(root)
    properties = []
    root.xpath('./Property').each do |node|
     
      cities = node.xpath(CITY_PATH).map{ |city| city.text.downcase }
      states = node.xpath(STATE_PATH).map{ |state| state.text.downcase }
      next if wrong_location?(cities, states)
      # puts "Adding property #{id}"
      property_hash = {}
      property_hash[:property_id] = node.xpath(PROPERTY_ID_PATH).text.to_i
      property_hash[:name] = node.xpath(NAME_PATH).first.text
      property_hash[:email] = node.xpath(EMAIL_PATH).first.text
      property_hash[:bedroom_count] = bedroom_count(node)
      property_hash[:latitude] = node.xpath('./ILS_Identification/Longitude').text
      property_hash[:longitude] = node.xpath('./ILS_Identification/Latitude').text
      properties << property_hash
    end
    properties
  end

  def bedroom_count(node)
    node.xpath(BEDROOM_PATH).map do |room|
      if room.xpath('./@RoomType').text.downcase == 'bedroom'
        room.xpath('./Count').first.text.to_i
      else
        0
      end
    end.sum
  end

  def wrong_location?(cities, states)
    !(cities.include?(CITY) && !(states & STATES).empty?)
  end

  def parse_xml(text)
    Nokogiri::XML(text)
  end

  def text_from_url
    open(@url).read
  end


end