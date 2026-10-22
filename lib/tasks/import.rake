desc 'Import contacts from a private external JSON file into an empty directory'
task import: :environment do
  count = UserImport.from_file(ENV.fetch('CONTACTS_PATH'))
  puts "#{count} user(s) imported."
end
