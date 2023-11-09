require 'yaml'
require 'fileutils'
require_relative 'apiclient'

class ImportCoda
	def run
		config = load_config

		domain = config['domain']
		in_path = config['paths']['in']
		out_path = config['paths']['out']
		accounts = config['accounts']

		abort 'Domain not set' if domain.empty?
		check_path(in_path)
		check_path(out_path)
		abort 'No accounts set' unless accounts.length > 0

		coda_files = list_files(in_path)
		puts "#{coda_files.length} CODA files found"
		for file in coda_files
			if import_file(file, domain, accounts)
				FileUtils.move file, File.join(out_path, File.basename(file))
			end
		end
	end

	def load_config
		return YAML.load_file("#{File.dirname(__FILE__)}/importcoda.yml") if File.exist? "#{File.dirname(__FILE__)}/importcoda.yml"
		abort "Config file importcoda.yml not found"
	end

	def check_path(path)
		abort "Path #{path} doesn't exist" unless File.exist?(path) and File.directory?(path)
		abort "Can't move files in path #{path}" unless File.writable?(path)
	end

	def list_files(path)
		Dir["#{path}/*.cod"]
	end

	def import_file(file, domain, accounts)
		begin
			content = File.read(file).strip
			parsed_content = ApiClient.new(domain, nil).post('coda/parse', content)
			
			iban = parsed_content[0]['account']['number']
			raise 'IBAN not found' if iban.empty?

			account = find_account(iban, accounts)
			unless account
				puts "#{file}: Skip file"
				return true
			end

			result = ApiClient.new(domain, account['apikey']).post('coda/import', content)
			puts "#{file}: Upload for #{account['name']} (#{result['transactions_success_count']}/#{result['transactions_count']} transactions)"

			return true;
		rescue => e
			puts "#{file}: Could not process"
			puts e.message

			return false
		end
	end

	def find_account(iban, accounts)
		for account in accounts
			return account if account['iban'].to_s == iban.to_s
		end
		return nil
	end
end

importcoda = ImportCoda.new
importcoda.run