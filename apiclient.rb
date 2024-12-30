require 'rest-client'
require 'json'

class ApiClient
	attr_accessor :domain, :apikey

	def initialize(domain, apikey=nil)
		self.domain = domain
		self.apikey = apikey
	end

	def build_headers
		headers = Hash.new
		headers['X-API-Key'] = apikey if apikey
		headers[:content_type] = :json
		headers[:accept] = :json

		return headers
	end

	def is_development?
		return domain =~ /^dev\./
	end

	def get(resource)
		response = nil
		if is_development?
			response = RestClient::Request.execute(
				method: :get, 
				url: "https://#{domain}/#{resource}",
			    headers: build_headers,
			    verify_ssl: false
			)
		else
			response = RestClient.get("https://#{domain}/#{resource}", build_headers)
		end

		throw Exception.new(response.body) unless response.code == 200

		return JSON.parse(response.body)
	end

	def download(resource)
		response = nil
		if is_development?
			response = RestClient::Request.execute(
				method: :get, 
				url: "https://#{domain}/#{resource}",
			    headers: build_headers,
			    verify_ssl: false
			)
		else
			response = RestClient.get("https://#{domain}/#{resource}", build_headers)
		end

		throw Exception.new(response.body) unless response.code == 200

		content_disposition = response.headers[:content_disposition]
		filename = ''
		if content_disposition && content_disposition.match(/filename="?(.+?)"?$/)
		  filename = content_disposition.match(/filename="?(.+?)"?$/)[1]
		end
		filename = nil if filename == ''

		return [response.body, filename]
	end

	def post(resource, content)
		headers = build_headers
		headers[:content_type] = 'application/x-www-form-urlencoded' if content.is_a?(Hash)

		response = nil
		if is_development?
			response = RestClient::Request.execute(
				method: :post, 
				url: "https://#{domain}/#{resource}",
			    headers: headers,
			    payload: content,
			    verify_ssl: false
			)
		else
			response = RestClient.post("https://#{domain}/#{resource}", content, headers)
		end

		throw Exception.new(response.body) unless response.code == 201 or response.code == 200
		
		return JSON.parse(response.body)
	end	

	def delete(resource)
		response = nil
		if is_development?
			response = RestClient::Request.execute(
				method: :delete, 
				url: "https://#{domain}/#{resource}",
			    headers: build_headers,
			    verify_ssl: false
			)
		else
			response = RestClient.delete("https://#{domain}/#{resource}", build_headers)
		end

		throw Exception.new(response.body) unless response.code == 200

		return JSON.parse(response.body)
	end

end