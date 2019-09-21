require 'socket'
require 'erb'
require 'cgi'
require_relative 'analyze'

# server
# https://openclassrooms.com/en/courses/4924041-handle-web-requests-with-ruby/5294666-using-the-request-path-to-create-pages
# erb 
# https://ruby-doc.org/stdlib-2.6.4/libdoc/erb/rdoc/ERB.html
server = TCPServer.new('127.0.0.1', 9888)

PAGES = {
"analyze" => "",
"upload" => ""
}

request_nr = 1

PAGE_NOT_FOUND = "Sorry, there's nothing here."

STATIC = {
	"/static/bootstrap.min.css" => "static/vendor/bootstrap/css/bootstrap.min.css",
	"/static/heroic-features.css" => "static/css/heroic-features.css",
	"/static/jquery.min.js" => "static/vendor/jquery/jquery.min.js",
	"/static/bootstrap.bundle.min.js" => "static/vendor/bootstrap/js/bootstrap.bundle.min.js"
}

# TODO
# Add logging

loop do
 	session = server.accept
 	http_method, path, protocol = session.gets.split(' ') # there are three parts to the request line
 	headers = {}
  	
  	while line = session.gets.split(' ', 2)             # Collect HTTP headers
		break if line[0] == ""                            # Blank line means no more headers
		headers[line[0].chop] = line[1].strip             # Hash headers by type
	end
	
	data = nil
	status = nil
	response_body = nil
	type = "text/plain"
	if STATIC.keys.include? path
		status = "200 OK"
		response_body = File.read(STATIC[path])
		puts STATIC[path].split(".")[-1]
		if STATIC[path].split(".")[-1] == "css"
			type = "text/css"
		elsif STATIC[path].split(".")[-1] == "js"
			type = "application/javascript"
		end

	else
		if http_method == "POST"
			data = session.read(headers["Content-Length"].to_i)  # Read the POST data as specified in the header
			puts data                                            # Do what you want with the POST data
		end

		path_parts = path.split("/")
	 
		#Checks
		puts "\nTests"
		puts "."+path_parts[1]+"."
		puts path_parts[1] == "upload"
		puts path_parts.length == 3
		puts "Len %d" % path_parts.length
		puts http_method == "POST"


		puts "Request \# %d - Method %s - Path %s - protocol %s" % [request_nr, http_method, path, protocol]

	if PAGES.keys.include? path_parts[1].chomp
		status = "200 OK"
		response_body = nil
		if path_parts[1] == "analyze" && http_method == "GET"
			#basepage - raw HTML
			type = "text/html"
			response_body = File.read('static/index.html')
		elsif path_parts[1] == "upload" && path_parts.length == 3 && /^\d{1,2}$/.match(path_parts[2]) && http_method == "POST"
			begin	    	
				# remove url encoding
				data = CGI.unescape(data)
				# Handle settings
				within_hr = path_parts[2].to_i
				# Send to analyze
				# Make frontend then try
				res = analyze(data, within_hr, false)
				# Show result
				template = ERB.new(File.read('result.erb'))
				response_body = template.result_with_hash(data: res)
			rescue
				status = "500 Internal Server Error"
				response_body = "Internal error - try again!"
			end
		else
			# Add
			response_body = PAGE_NOT_FOUND
		end
					
		else
			status = "404 Not Found"
			response_body = PAGE_NOT_FOUND
		end
	end

	session.puts <<-HEREDOC
HTTP/1.1 #{status}
Content-Type: #{type}

#{response_body}
	HEREDOC

	session.close
	request_nr += 1
end