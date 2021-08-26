require 'aws-sdk-dynamodb'

module DynamoDB
  def add_item_to_table(table_item, table_name, key_attributes)
    dynamodb_client.put_item(item: formatted_item(table_item, key_attributes), table_name: table_name)
  rescue StandardError => e
    puts "Error adding property: #{e}" 
  end

  def dynamodb_client
    @dynamodb_client ||= Aws::DynamoDB::Client.new
  end

  def add_items(items, table_name, key_attributes)
    items.each do |item|
      add_item_to_table(item, table_name, key_attributes)
    end
  end

  def formatted_item(item, key_attributes)
    raise 'Expected a hash for table input' unless item.is_a? Hash
    new_hash = { 'info' => {} }

    item.each do |k, v|
      if key_attributes.include?(k)
        new_hash[k] = v
      else
        new_hash['info'][k] = v
      end
    end
  end
end