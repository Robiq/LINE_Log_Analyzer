require 'date'
#Done

# Get # of messages sent
# Gather # of stamps sent
# Gather # of images sent
# Find most used word(s)
# Find least used word(s)
# Gather # of stamps pr sender
# Gather # of images pr. sender
# Gather msg pr. sender

#TODO

# Gather unique # of words pr. sender
# Find most used word pr. sender
# Find least used word pr. sender
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
		sender_message[sender] = [{date: datetime, msg:ent.LINE.msg, type: ent.LINE.type}]
	else
		sender_message[sender].push({date: datetime, msg:ent.LINE.msg, type: ent.LINE.type})
	end
end

def add_word_data(word, words)
	word = word.downcase
	#puts "Word lower: " + word
	word.gsub!(/[\(\)]/, ' ')
	#puts word
	word.gsub!(/[^0-9A-Za-z ]/, '')
	#puts "Word strip: " + word

	#Handle spaces added as part of cleaning
	word = word.split

	for w in word
		# todo - remove filler word. (the, this, that...etc)
		ignore_words = ["to","of","in","for","on","with","at","by","from","up","about","into","over","after","Others","the","and","a","that","I","it","not","he","as","you","this","but","his","they","her","she","or","an","will","my","one","all","would","there","their"]
		if ignore_words.include? w
			return
		end

		if words[w] == nil
			words[w] = 1
		else
			words[w] += 1
		end
	end
end

def analyze_pr_sender(data)
	#Data
	# Name, [ent, ent]
	# ent = [datetime, msg, type]
	
	#Res
	# res[usr] = {msg_stats: {msg_nr, stamp_nr, photo_nr}, word_stats: {uniq, most, least}, reply_time}
	res = Hash.new()

	#puts data
	data.each_key do |user|
		#puts "Key: " + user
		#puts data[user]
		res[user] = {msg_stats: {text_nr:0, stamp_nr:0, photo_nr:0}, word_stats: {uniq:0, most:0, least:0}, reply_time:nil}
		data[user].each do |msg_data|
			#puts msg_data
			if msg_data[:type] == "p"
				res[user][:msg_stats][:photo_nr] += 1
			elsif msg_data[:type] == "s"
				res[user][:msg_stats][:stamp_nr] += 1
			else
				res[user][:msg_stats][:text_nr] += 1
			end
			
						

		end
		puts "Stats for user: " + user
		puts "Stamps: " + res[user][:msg_stats][:stamp_nr].to_s
		puts "Photos: " + res[user][:msg_stats][:photo_nr].to_s
		puts "Text: " + res[user][:msg_stats][:text_nr].to_s
		puts "Total messages: " + (res[user][:msg_stats][:stamp_nr] + res[user][:msg_stats][:photo_nr] + res[user][:msg_stats][:text_nr]).to_s + "\n"
	end
	#for user in data
	#	puts user
	#end
end

def analyze_reply_time(one, two)
	return
end

def analyze_lines(chat)
	msg_amt = chat.length
	#puts msg_amt
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
		
		# Need forward analysis (next message not from sender == calculate reply time and recalculate avg time)
		if ent.LINE.msg.include? "?"
			analyze_reply_time(sender, datetime)
		end
	end

	analyze_pr_sender(sender_message)

	#puts "---------------------- OUTPUT ---------------------------"
	#puts "Messages: "
	#puts sender_message
	#puts "Words: "
	#puts words
	#puts "Stickers: " + stickers.to_s
	#puts "Images: " + images.to_s
	#puts "Chat messages: " + chat_txt.to_s
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
				#puts "Date: "+date_raw
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