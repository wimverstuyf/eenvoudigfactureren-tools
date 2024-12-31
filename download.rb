require 'yaml'
require 'fileutils'
require 'date'
require_relative 'apiclient'

class Download
	def run
		config = load_config

		file_type = config['type'] ? config['type'] : 'invoices'
		file_format = config['format'] ? config['format'] : 'pdf'
		file_format = 'pdf' unless file_format == 'pdf' || file_format == 'ubl' || file_format == 'peppol'

		out_path = config['path'] ? config['path'].gsub('\\', '/') : nil
		filter_from = translate_date_start(config['filter'] ? config['filter']['from'] : nil)
		filter_until = translate_date_end(config['filter'] ? config['filter']['until'] : nil)
		filter_tag = config['filter'] ? config['filter']['tag'] : nil
		action = config['action'] ? config['action'] : nil
		accounts = config['accounts']

		if accounts && accounts.length > 0
			for account in accounts
				run_for_account(account, file_type, file_format, out_path, filter_from, filter_until, filter_tag, action)
			end
		else
			run_for_apikey(config['apikey'], file_type, file_format, out_path, filter_from, filter_until, filter_tag, action, "")
		end
	end

	def quarter_dates(quarter, year)
	  case quarter
	  when 1
	    [Date.new(year, 1, 1), Date.new(year, 3, 31)]
	  when 2
	    [Date.new(year, 4, 1), Date.new(year, 6, 30)]
	  when 3
	    [Date.new(year, 7, 1), Date.new(year, 9, 30)]
	  when 4
	    [Date.new(year, 10, 1), Date.new(year, 12, 31)]
	  end
	end

	def translate_date_start(date)
		return Date.today.strftime("%Y-%m-01") if date == 'MONTH'
		return Date.today.prev_month.strftime("%Y-%m-01") if date == 'PREVMONTH'
		return Date.today.next_month.strftime("%Y-%m-01") if date == 'NEXTMONTH'

		if date =~ /QUARTER/ 
			current_quarter = ((Date.today.month - 1) / 3) + 1
			current_year = Date.today.year

			if date == 'QUARTER'
				quarterStart, quarterEnd = quarter_dates(current_quarter, current_year)
				return quarterStart.strftime("%Y-%m-%d")
			end
			if date == 'PREVQUARTER'
				if current_quarter == 1
				  previous_quarter = 4
				  previous_year = current_year - 1
				else
				  previous_quarter = current_quarter - 1
				  previous_year = current_year
				end

				quarterStart, quarterEnd = quarter_dates(current_quarter, current_year)
				return quarterStart.strftime("%Y-%m-%d")
			end
			if date == 'NEXTQUARTER'
				if current_quarter == 4
				  next_quarter = 1
				  next_year = current_year + 1
				else
				  next_quarter = current_quarter + 1
				  next_year = current_year
				end
				quarterStart, quarterEnd = quarter_dates(current_quarter, current_year)
				return quarterStart.strftime("%Y-%m-%d")
			end
		end

		return Date.today.strftime("%Y-01-01") if date == 'YEAR'
		return Date.today.prev_year.strftime("%Y-01-01") if date == 'PREVYEAR'
		return Date.today.next_year.strftime("%Y-01-01") if date == 'NEXTYEAR'

		return date
	end

	def translate_date_end(date)
		return Date.new(Date.today.year, Date.today.month, -1).strftime("%Y-%m-%d") if date == 'MONTH'
		return Date.new(Date.today.prev_month.year, Date.today.prev_month.month, -1).strftime("%Y-%m-%d") if date == 'PREVMONTH'
		return Date.new(Date.today.next_month.year, Date.today.next_month.month, -1).strftime("%Y-%m-%d") if date == 'NEXTMONTH'

		if date =~ /QUARTER/ 
			current_quarter = ((Date.today.month - 1) / 3) + 1
			current_year = Date.today.year

			if date == 'QUARTER'
				quarterStart, quarterEnd = quarter_dates(current_quarter, current_year)
				return quarterEnd.strftime("%Y-%m-%d")
			end
			if date == 'PREVQUARTER'
				if current_quarter == 1
				  previous_quarter = 4
				  previous_year = current_year - 1
				else
				  previous_quarter = current_quarter - 1
				  previous_year = current_year
				end

				quarterStart, quarterEnd = quarter_dates(current_quarter, current_year)
				return quarterEnd.strftime("%Y-%m-%d")
			end
			if date == 'NEXTQUARTER'
				if current_quarter == 4
				  next_quarter = 1
				  next_year = current_year + 1
				else
				  next_quarter = current_quarter + 1
				  next_year = current_year
				end
				quarterStart, quarterEnd = quarter_dates(current_quarter, current_year)
				return quarterEnd.strftime("%Y-%m-%d")
			end
		end

		return Date.today.strftime("%Y-12-31") if date == 'YEAR'
		return Date.today.prev_year.strftime("%Y-12-31") if date == 'PREVYEAR'
		return Date.today.next_year.strftime("%Y-12-31") if date == 'NEXTYEAR'

		return date
	end

	def run_for_account(account, file_type, file_format, default_out_path, default_from, default_until, default_tag, default_action)
		apikey = account['apikey']
		accountname = account['name'] ? account['name'] : ''

		abort 'Apikey not set' unless apikey

		out_path = account['path'] ? account['path'].gsub('\\', '/') : default_out_path
		filter_from = translate_date_start(account['filter'] && account['filter']['from'] ? account['filter']['from'] : default_from)
		filter_until = translate_date_end(account['filter'] && account['filter']['until'] ? account['filter']['until'] : default_until)
		filter_tag = config['filter'] && account['filter']['tag'] ? account['filter']['tag'] : default_tag
		action = config['action'] ? config['action'] : default_action

		run_for_apikey(apikey, file_type, file_format, out_path, filter_from, filter_until, filter_tag, action, "#{accountname}: ")
	end

	def list(apikey, file_type, filter_from, filter_until, filter_tag)
		querystring = '&filter='
		querystring += "date__ge__#{filter_from}," if filter_from
		querystring += "date__le__#{filter_until}," if filter_until

		if filter_tag
			if filter_tag =~ /^not:/
				querystring += "tag__ne__#{filter_tag[4..]},"
			else
				querystring += "tag__eq__#{filter_tag},"
			end
		end

		querystring = '' if querystring == '&filter='
		querystring = querystring.chop # remove last comma

		return ApiClient.new(@domain, apikey).get("/api/v1/#{file_type}?format=json#{querystring}")
	end

	def download(apikey, document_id, file_type, file_format, path)
		file_format = 'ublbe' if file_type == 'ubl'
		file_format = 'peppolbis3' if file_type == 'peppol'

		content, filename = ApiClient.new(@domain, apikey).download("/api/v1/#{file_type}/#{document_id}?format=#{file_format}")
		filename = "#{document_id}.pdf" if filename == nil && file_format == 'pdf'
		filename = "#{document_id}.xml" if filename == nil && file_format != 'pdf'

		file_path = File.join(path, filename)
		File.open(file_path, "w") do |file|
		  file.write(content)
		end
		puts "File #{filename} downloaded"
	end

	def mark_sent_accountant(apikey, document_id)
		begin
			result = ApiClient.new(@domain, apikey).post("/api/v1/invoices/#{document_id}/sendaccountant?format=json", {mark_as_sent: "1"})
			error = result['error'] ? result['error'] : nil

			if error != nil
				puts "File could not be marked as sent to accounting (#{error})"
			end
		rescue => e
			puts "File could not be marked as sent to accounting (#{e.message})"
		end
	end

	def get_document_id(document, file_type)
		document_id = nil
		case file_type
		when "invoices"
			document_id = document['invoice_id']
		when "receipts"
			document_id = document['receipt_id']
		when "quotes"
			document_id = document['quote_id']
		when "orders"
			document_id = document['order_id']
		when "deliveries"
			document_id = document['delivery_id']
		when "paymentrequests"
			document_id = document['paymentrequest_id']
		when "customdocuments"
			document_id = document['customdocument_id']
		end

		return document_id
	end

	def run_for_apikey(apikey, file_type, file_format, out_path, filter_from, filter_until, filter_tag, action, prefix)
		abort 'Apikey not set' unless apikey

		documents = list(apikey, file_type, filter_from, filter_until, filter_tag)
		puts "#{prefix}Nothing found" if documents.length == 0
		puts "#{prefix}#{documents.length} documents found" if documents.length > 0

		for document in documents
			document_id = get_document_id(document, file_type)
			download(apikey, document_id, file_type, file_format, build_path(out_path, document['date']))
			
			if action == 'mark-sent-accountant' && file_type == 'invoices'
				mark_sent_accountant(apikey, document_id)
			end
		end
	end

	def load_config
		config = YAML.load_file(File.join(File.dirname(__FILE__), "download.yml")) if File.exist? File.join(File.dirname(__FILE__), "download.yml") 
		abort "Config file download.yml not found" unless config

		@domain = config['domain']
		abort 'Domain not set' if @domain.empty?
		return config
	end

	def build_path(path, date)
		date = Date.parse(date)

		path = path.gsub('{yyyy}', date.year.to_s)
		path = path.gsub('{mm}', date.strftime("%m"))
		path = path.gsub('{dd}', date.strftime("%d"))
		path = path.gsub('{yyyy-mm}', date.strftime("%Y-%m"))
		path = path.gsub('{yyyy-mm-dd}', date.strftime("%Y-%m-%d"))

		current_quarter = ((date.month - 1) / 3) + 1
		path = path.gsub('{q}', current_quarter.to_s)

		unless Dir.exist?(path)
		  FileUtils.mkdir_p(path)
		  puts "Directory created: #{path}"
		end

		abort "Path not set" unless path
		abort "Path #{path} doesn't exist" unless File.exist?(path) and File.directory?(path)
		abort "Path #{path} not writable" unless File.writable?(path)

		return path
	end
end

download = Download.new
download.run
