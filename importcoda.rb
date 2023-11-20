require 'yaml'
require 'fileutils'
require_relative 'apiclient'

class ImportCoda
	def run
		config = load_config

		in_path = config['paths'] ? config['paths']['in'].gsub('\\', '/').gsub('{yyyy}', Date.today.year.to_s) : nil
		out_path = config['paths'] ? config['paths']['out'].gsub('\\', '/').gsub('{yyyy}', Date.today.year.to_s) : nil

		accounts = config['accounts']

		if accounts && accounts.length > 0
			if in_path
				run_for_files(in_path, out_path, accounts)
			else
				for account in accounts
					run_for_account(account, out_path)
				end
			end
		else
			run_for_apikey(in_path, out_path, config['apikey'])
		end
	end

	def run_for_files(in_path, out_path, accounts)
		check_path(in_path)
		check_path(out_path)

		coda_files = list_files(in_path)
		puts "#{coda_files.length} CODA files found"
		for file in coda_files
			begin
				account = find_account(file, accounts)
				if !account or import_file(file, account['apikey'])
					FileUtils.move file, File.join(out_path, File.basename(file))			
				end
			rescue => e
				puts "#{File.basename(file)}: Could not process"
				puts e.message

				return false
			end
		end
	end

	def run_for_account(account, default_out_path)
		in_path = account['paths'] ? account['paths']['in'].gsub('\\', '/').gsub('{yyyy}', Date.today.year.to_s) : nil
		out_path = account['paths'] ? account['paths']['out'].gsub('\\', '/').gsub('{yyyy}', Date.today.year.to_s) : default_out_path
		apikey = account['apikey']
		accountname = account['name'] ? account['name'] : ''

		check_path(in_path)
		check_path(out_path)
		abort 'Apikey not set' unless apikey

		coda_files = list_files(in_path)
		puts "#{accountname}: #{coda_files.length} CODA files found"
		for file in coda_files
			if import_file(file, apikey)
				FileUtils.move file, File.join(out_path, File.basename(file))
			end
		end
	end

	def run_for_apikey(in_path, out_path, apikey)
			abort 'Apikey not set' unless apikey

			check_path(in_path)
			check_path(out_path)

			coda_files = list_files(in_path)
			puts "#{coda_files.length} CODA files found"
			for file in coda_files
				if import_file(file, apikey)
					FileUtils.move file, File.join(out_path, File.basename(file))
				end
			end
	end

	def load_config
		config = YAML.load_file(File.join(File.dirname(__FILE__), "importcoda.yml")) if File.exist? File.join(File.dirname(__FILE__), "importcoda.yml") 
		abort "Config file importcoda.yml not found" unless config

		@domain = config['domain']
		abort 'Domain not set' if @domain.empty?
		return config
	end

	def check_path(path)
		abort "Path not set" unless path
		abort "Path #{path} doesn't exist" unless File.exist?(path) and File.directory?(path)
		abort "Path #{path} not writable" unless File.writable?(path)
	end

	def list_files(path)
		Dir[File.join(path, "*.cod")]
	end

	def find_account(file, accounts)
		content = File.read(file).strip
		parsed_content = ApiClient.new(@domain, nil).post('coda/parse', content)
		
		iban = parsed_content[0]['account']['number']
		raise 'IBAN not found' if iban.empty?

		iban.strip!
		for account in accounts
			abort 'IBAN not set' unless account['iban']
			return account if account['iban'].to_s == iban.to_s
		end

		puts "#{File.basename(file)}: Skip file (IBAN #{iban})"
		return nil
	end

	def import_file(file, apikey)
		begin
			result = ApiClient.new(@domain, apikey).post('coda/import', File.read(file).strip)
			puts "#{File.basename(file)}: Upload (#{result['transactions_success_count']}/#{result['transactions_count']} transactions)"

			return true;
		rescue => e
			puts "#{File.basename(file)}: Could not process"
			puts e.message

			return false
		end
	end
end

importcoda = ImportCoda.new
importcoda.run