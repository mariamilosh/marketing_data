require 'csv'
require 'yaml'

PREFIXES = ["Mr.", "Mrs.", "Ms.", "Miss", "Dr."]
LAST_NAME_PREFIX = ["Van", "Von", "Le", "La", "Les"]
LAST_NAME_SUFFIX = ["Jr.", "Sr.", "I", "II", "III", "IV", "V", "VI", "VII"]

CONTACT_NAME_HEADER = "Contact"
SALUTATION_HEADER = "Salutation"
CONTACT_TITLE_HEADER = "Contact Title"
# ruby_county_format.rb must exist in a directory with a yaml file containing
# a hash with the key "csv_directory" and string value of the directory
# containing the csv files to parse
# Names on columns 11, 13, 15, 17, 19
# Titles on columns 12, 14, 16, 18, 20
# Rename titles on columns 9 - 10
# Delete columns 21 - 23, 8, 6, 3, 2

# sample_names = [["Dr.", "Eddie", "Van", "Quin"], ["Ms.", "Casey", "Sinclair", "III"],
# ["Mark", "Von", "Clark"], ["Mr.", "Larry", "Johnson"], ["Mr.", "Sal", "Von", "Clark", "IV"]]

def has_prefix?(name_arr)
  PREFIXES.include?(name_arr[0])
end

def has_lastname_prefix?(name_arr)
  i = -2
  if has_suffix?(name_arr)
    i -= 1
  end
  LAST_NAME_PREFIX.include?(name_arr[i])
end

def has_suffix?(name_arr)
  LAST_NAME_SUFFIX.include?(name_arr[-1])
end

def get_contact_name(name_str)
  contact_name = [] + separate_string(name_str)
  if has_prefix?(contact_name)
    contact_name.shift
    contact_name.join(" ")
  else
    contact_name.join(" ")
  end
end

def get_salutation(name_str)
  salutation = [] + separate_string(name_str)
  if !has_prefix?(salutation)
    return get_contact_name(salutation)
  else
    salutation.pop if has_suffix?(salutation)
    if has_lastname_prefix?(salutation)
      salutation.slice!(1..-3)
    else
      salutation.slice!(1..-2)
    end
  end
  salutation.join(" ")
end

def separate_string(name_str)
  name_str.split(" ")
end

# def add_contact(name_header, title_header, row)
#     row[CONTACT_TITLE_HEADER] = row[title_header]
#     row[CONTACT_NAME_HEADER] = get_contact_name(row[name_header])
#     row[SALUTATION_HEADER] = get_salutation(row[name_header])
# end
def add_contact(name_and_title_arr, row)
  row[CONTACT_TITLE_HEADER] = name_and_title_arr[0]
  row[CONTACT_NAME_HEADER] = get_contact_name(name_and_title_arr[1])
  row[SALUTATION_HEADER] = get_salutation(name_and_title_arr[1])
end

def add_generic_contact(row)
  row[CONTACT_TITLE_HEADER] = "N/a"
  row[CONTACT_NAME_HEADER] = "Plant Manager"
  row[SALUTATION_HEADER] = "Sir/Madam"
end
# name and title_header allow count of 1 through 4
def get_name_header(count)
  name_header = "Name" + count.to_s
end

def get_title_header(count)
  title_header = "Title" + count.to_s
end

yaml_data = YAML.load(File.read("local_vars.yml"))
csv_dir = Dir.new(yaml_data["csv_directory"])

csv_dir.each do |file|
  next if File.directory?(file)
  ab_path = File.join(csv_dir, file)
  county_data  = CSV.parse(File.read(ab_path), headers: true)
  county_data_array = county_data.to_a

  name_header = nil
  title_header = nil
  contact_array = []
  county_data.each do |row|
    company_contact = nil
    count = 1
    contact_count = 0
    loop do
      name_header = get_name_header(count)
      title_header = get_title_header(count)
      row["num_contacts"] = contact_count
      count += 1
      if row[name_header] != nil
        company_contact = true
        contact_array << [row[title_header], row[name_header]]
        contact_count += 1
      end
      break if count > 5
    end
    if !company_contact
      # Create generic contact and salutation fields
      row["num_contacts"] = 0
      contact_array << [nil]
      add_generic_contact(row)
    end
  end
  total_rows = county_data.size
  row_count = 0
  county_data.by_row!

  loop do
    c = county_data[row_count]["num_contacts"]
    #p county_data[row_count]
    #p county_data[row_count]["num_contacts"]
    #break if county_data[row_count]["num_contacts"] == 0
    loop do
      break if county_data[row_count]["num_contacts"] == 0
      break if c <= 1
      county_data.push(county_data[row_count])
      c -= 1
    end
    row_count += 1
    break if row_count >= total_rows
  end
  #puts county_data
  #
  # county_data_array = county_data.to_a
  # #p county_data_array
  # county_data_array_headers = county_data_array.shift
  # #p county_data_array
  # county_data_array.sort_by! {|n| n.values_at(0)}
  # county_data_array.unshift(county_data_array_headers)
  # #county_data_array.flatten!()
  # #county_data_array.flatten!()
  # #county_data_array = county_data_array_headers.push(county_data_array)
  # #new_array = [county_data_array_headers]+ [county_data_array].flatten
  # #county_data = county_data_array.to_csv(headers: true)
  # #county_data = new_array.to_csv
  # p county_data_array
  # county_data = CSV.parse(county_data_array.join("\\"), headers: true)
  # p county_data
  # #county_data = county_data_array.to_csv
  # #p county_data
  #county_data_new = CSV::Table.new([county_data[0]]+county_data[1..].sort_by{ |r| r[0] })
  county_data = CSV::Table.new([county_data[0]]+county_data[1..].sort_by{ |r| r[0].downcase })
  #puts county_data
  #p contact_array[0]
  #total_rows = county_data.size

  # Use delete(headers) to delete columns
  # county_data.each do |row|
  #   count = 1
  #   num_contacts = row["num_contacts"]
  #   #puts row
  #   loop do
  #     #name_header = get_name_header(count)
  #     #puts name_header
  #     #puts row[name_header]
  #     #title_header = get_title_header(count)
  #     #puts title_header
  #     #puts row[title_header]
  #     #row["num_contacts"]
  #     #p name_header
  #     #if row[name_header] != nil
  #     if contact_array[0] != nil
  #       #p row
  #       p contact_array[0]
  #
  #       add_contact(contact_array[0], row)
  #       #p row
  #       contact_array.shift
  #       #row[name_header] = nil
  #       #row[title_header] = nil
  #     else
  #       contact_array.shift
  #     end
  #     count += 1
  #     break if count > num_contacts
  #   end
  # end

  # total_rows = county_data.size
  # puts total_rows
  # row_count = 0
  # # Use delete(headers) to delete columns
  # loop do
  #   count = 1
  #   loop do
  #     name_header = get_name_header(count)
  #     #puts name_header
  #     #puts row[name_header]
  #     title_header = get_title_header(count)
  #     #puts title_header
  #     #puts row[title_header]
  #     #row["num_contacts"]
  #     #p name_header
  #     #p county_data[row_count]
  #     if county_data[row_count][name_header] != nil
  #       #p county_data[row_count]
  #       add_contact(name_header, title_header, county_data[row_count])
  #     end
  #     count += 1
  #     break if count > 5
  #   end
  #   row_count += 1
  #   break if row_count >= county_data.size
  # end

#############################
  #p county_data[1]
  #p contact_array

  total_rows = county_data.size
  count = 0

  contact_array.each do |person|
    if person != [nil]
      add_contact(person, county_data[count])
    end
    p county_data[count]["Contact"]
    #p person
    count += 1
  end
  county_data.each { |row| p row["Contact"]}
  #puts county_data
end
