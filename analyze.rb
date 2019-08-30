# If text contains "?" find response time
# Gather all unique words pr. sender
# Find most used word pr. sender
# Find least used word pr. sender
# Find most used word(s)
# Find least used word(s)
# Gather msg pr. sender
# Gather # of stamps sent
# Gather # of images sent
# Find message distribution (% sent by each participant)

def readfile(filename)
	return IO.readlines(filename)
end

# TIMESTAMP [TAB] SENDER_FIRSTNAME [SPACE] SENDER_LASTNAME [SPACE] MESSAGE
# TIMESTAMP = 1:23 OR 12:34
def analyze(line)
	line = line.chomp()
	#https://www.rubyguides.com/2015/06/ruby-regex/
	parse_line = line.match(FORMAT) { |m| LINE.new(*m.captures, "m") }
	#puts parse_line
	if parse_line.msg == "[Photo]"
		parse_line.type = "p"
	elsif parse_line.msg == "[Sticker]"
		parse_line.type = "s"
	end
	return parse_line
end


LINE = Struct.new(:time, :sender, :msg, :type)
FORMAT = /(\d{1,2}:\d{2})\s?(\w*\s?\w*)\s?(.*)/

DATE_STR = Struct.new(:year, :month, :day, :weekday)
DATE_FORMAT = /(\d{4})\/(\d{2})\/(\d{2})\((\w{3})\)/

ChatEntr = Struct.new(:LINE, :date)

if ARGV.length  < 1
	puts "Usage: analyze.rb <full_path_chat_file>"
else
	for arg in ARGV
		chat=[]
		date=""
		filecontents = readfile(arg)
		for line in filecontents
		#	puts f
		#	puts line[4].ord
			if line.include? "\t"
				tmp = ChatEntr.new(analyze(line), date)
				#puts tmp
				chat.push(tmp)
			elsif line.start_with?('2')
				date_raw = line.chomp()
				#puts "Date: "+date_raw
				date = date_raw.match(DATE_FORMAT) { |m| DATE_STR.new(*m.captures) }
			end
		end
		#puts "here"
		#puts date.year.to_i - 2
		puts chat
	end
end