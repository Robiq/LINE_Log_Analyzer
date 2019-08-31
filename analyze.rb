require 'date'
#Done

# Get # of messages sent
# Gather # of stamps sent
# Gather # of images sent
# Find most used word(s)
# Find least used word(s)

#TODO

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
	#puts "LINE: "+line
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

def find_datetime(ent)
	format = "%Y/%m/%d-%a %k:%M"
	date = ent.date.year+"/"+ent.date.month+"/"+ent.date.day+"-"+ent.date.weekday
	time = ent.LINE.time
	if time[0..1] == "24"
		time[0..1] = "00"
	end
	#puts date
	#puts time
	#puts date+" "+time
	return DateTime.strptime(date+" "+time, format)
end

def add_sender_data(sender, datetime, ent, sender_message)
	if sender_message[sender] == nil
		sender_message[sender] = [[datetime, ent.LINE.msg, ent.LINE.type]]
	else
		sender_message[sender].push([datetime, ent.LINE.msg, ent.LINE.type])
	end
end

def add_word_data(word, words)
	word = word.downcase
	puts "Word lower: " + word
	word.gsub!(/[^0-9A-Za-z]/, '')
	puts "Word strip: " + word

	# todo - remove filler word. (the, this, that...etc)

	if words[word] == nil
		words[word] = 1
	else
		words[word] += 1
	end
end

def analyze_lines(chat)
	msg_amt = chat.length
	puts msg_amt
	# words[word] = frequency
	words = {}
	sender_message = Hash.new()
	stickers = 0
	images = 0
	chat_txt = 0

	#Plan:
	# Get data for all messages
	# Get data for each participant
	# Compare as verification
		# if matching, remove data for all messages
	for ent in chat
		#puts ent
		datetime = find_datetime(ent)
		sender = ent.LINE.sender
		
		#Add all chats to an array in a hash, indexed by sender
		add_sender_data(sender, datetime, ent, sender_message)
		
		#Add all words to hash
		if ent.LINE.type == "m"
			for word in ent.LINE.msg.split
				add_word_data(word, words)
			end
		end



		if ent.LINE.type == "s"
			stickers += 1
		elsif ent.LINE.type == "p"
			images += 1
		else
			chat_txt += 1
		end
	end
	puts "Messages: "
	puts sender_message
	puts "Words: "
	puts words

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
		# Jump to beginning of history
		filecontents.shift(3)
		for line in filecontents
			# Debug
			#if date == nil
			#	puts line
			#	exit
			#end
			#puts line
		#	puts line[4].ord
			
			# Get date
			if line.start_with?('201')
				date_raw = line.chomp()
				puts "Date: "+date_raw
				date = date_raw.match(DATE_FORMAT) { |m| DATE_STR.new(*m.captures) }
			
			#Multiline support handling
			elsif not line.start_with?(/\d{1,2}:\d{2}/) and not /\S/ !~ line
				chat[-1].LINE.msg += "\n"+line.chomp()
				#puts chat[-1]
				#puts chat[-1].LINE.msg

			# Extract data
			elsif not /\S/ !~ line
				tmp = ChatEntr.new(extract(line), date)
				#puts tmp
				chat.push(tmp)
			end
		end
		#puts "here"
		#puts date.year.to_i - 2
		#puts chat
		analyze_lines(chat)
	end
end