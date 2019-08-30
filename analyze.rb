#Done

# Get # of messages sent
# Gather # of stamps sent
# Gather # of images sent

#TODO

# Find most used word(s)
# Find least used word(s)

# Gather all unique words pr. sender
# Find most used word pr. sender
# Find least used word pr. sender
# Gather # of stamps pr sender
# Gather # of images pr. sender
# Gather msg pr. sender
# Find message distribution (% sent by each participant)

# If text contains "?" find response time

def readfile(filename)
	return IO.readlines(filename)
end

# TIMESTAMP [TAB] SENDER_FIRSTNAME [SPACE] SENDER_LASTNAME [SPACE] MESSAGE
# TIMESTAMP = 1:23 OR 12:34
def extract(line)
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

def analyze_lines(chat)
	msg_amt = chat.length
	puts msg_amt
	# words[word] = frequency
	words = {}
	stickers = 0
	images = 0
	chat_txt = 0

	#Plan:
	# Get data for all messages
	# Get data for each participant
	# Compare as verification
		# if matching, remove data for all messages
	for ent in chat
		if ent.LINE.type == "s"
			stickers += 1
		elsif ent.LINE.type == "p"
			images += 1
		else
			chat_txt += 1
		end
	end
	puts "Stickers: " + stickers.to_s
	puts "Images: " + images.to_s
	puts "Chat messages: " + chat_txt.to_s
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
		chat=Array.new()
		date=""
		filecontents = readfile(arg)
		for line in filecontents
		#	puts f
		#	puts line[4].ord
			if line.include? "\t"
				tmp = ChatEntr.new(extract(line), date)
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
		#puts chat
		analyze_lines(chat)
	end
end