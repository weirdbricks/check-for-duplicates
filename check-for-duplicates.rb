#!/usr/bin/env ruby

#by Lampros Chaidas for WeirdBricks
#checks for duplicate files under /unprocessed-photos
#if duplicates are found, ignores and e-mails
#if all well still e-mails

#gem install sequel --no-ri --no-rdoc
#yum install sqlite-devel
#gem install sqlite3 --no-ri --no-rdoc
#gem install mail --no-ri --no-rdoc

require 'date'
require 'digest'
require 'sequel'
require 'sqlite3'
require 'mail'

sqlite3="/home/weirdbricks/processed-photos.db"
source_directory="/home/weirdbricks/unprocessed-photos/*"
target_directory="/home/weirdbricks/archived-photos"

#CHANGE THOSE E-MAIL SETTINGS FOR OUTGOING E-MAIL
options = { :address              => "mail.gmx.com",
            :port                 => 465,
            :domain               => 'mail.gmx.com',
            :user_name            => '',
            :password             => '',
            :authentication       => 'plain',
            :enable_starttls_auto => true  }

DB = Sequel.sqlite(sqlite3)
$logfile = "/home/weirdbricks/duplicates"+DateTime.now.strftime("%H-%M_%m-%d-%Y")+".log"

#create the tables only if the file doesn't exist!
unless File.exists?(sqlite3)
  DB.create_table :photos do
    primary_key :id
    String :filename
    Integer :size
    String :hash
   end
end

#a function that logs messages to a file
def log(text)
   puts text
   `echo "#{text}" >> #{$logfile}`
end

def remove_spaces_from_directories(directories)
  directories.each do |item|
    #we don't want to keep spaces, so find them and rename them
    if item.include?(" ")
      log "Directory #{item} has a space!"
      newitem=item.gsub(" ","_")
      puts newitem
      #renaming (moving) directory
      log "Renaming directory: #{item}"
      `mv "#{item}" #{newitem}`
       if Dir.exists?(newitem)
         log "Renaming of directory: #{item} SUCCESS"
       end
    end
  end
end

#get directories and split them on \n, which makes them an array
directories = `find #{source_directory} -type d`.split("\n")
log "Checking directories for spaces.."
remove_spaces_from_directories directories

dataset = DB[:photos]

#go through each directory and process files
directories.each do |directory|
  files=`find /home/weirdbricks/unprocessed-photos/* -type f`.split("\n")
  #go through each file calculate it's hash and check if it exists in the database
  files.each do |file|
    hash = Digest::SHA1.hexdigest File.read(file)
    size = File.size(file)
    result = dataset.where(:hash=>hash)
    if result.count==0
    log "INFO: file #{file} is new - adding to the database - HASH: #{hash}, SIZE: #{size}"
      dataset.insert(:filename => file,
                     :size => size,
                     :hash => hash)
    else
      log "WARNING: file: #{file} already exists! skipping!"
    end

  end

end

email=""
File.readlines($logfile).each do |line| 
  if line.include?"WARNING"
    email="YES"
  end
end

if email=="YES" 
  puts "sending e-mail"
  Mail.deliver do
    to 'thehauntedmind@netscape.net'
    from 'lampros.chaidas@gmx.com'
    subject 'warnings!'
    body 'haha some body goes here'
  end
end
