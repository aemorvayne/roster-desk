class UserImport
  PASSWORD_BYTES = 32
  Error = Class.new(StandardError)
  def self.from_file(path)
    file = Pathname.new(path).realpath
    raise Error, 'Keep contact files outside the application directory.' if file.to_s.start_with?("#{Rails.root}/")
    File.open(file) { |input| new.call(input) }
  end

  def call(input)
    records = JSON.parse(input.read)
    validate_records(records)
    User.transaction { import_records(records) }
  rescue JSON::ParserError, KeyError, ArgumentError, TypeError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    raise Error, 'The file contains invalid or duplicate contacts. Nothing was imported.'
  end

  def validate_records(records)
    return if records.is_a?(Array) && records.all?(Hash)
    raise Error, 'The contact file must contain an array of records.'
  end

  def import_records(records)
    User.connection.execute('LOCK TABLE users IN EXCLUSIVE MODE')
    raise Error, 'Import requires an empty directory; existing accounts were preserved.' if User.exists?
    records.each { |record| User.create!(attributes(record)) }
    records.length
  end

  def attributes(record)
    fields = record.slice('full_name', 'email', 'job_position', 'status').symbolize_keys
    fields.merge(password: SecureRandom.hex(PASSWORD_BYTES), last_login_at: Time.iso8601(record.fetch('last_seen')))
  end
end
