#!/usr/bin/env ruby

#by Lampros Chaidas for WeirdBricks
#checks for duplicate files under /uploads
#if duplicates are found, ignores and e-mails
#if all well still e-mails

require 'date'

source_directory="/home/weirdbricks/unprocessed-photos/*"
target_directory="/home/weirdbricks/archived-photos"

#a function that logs directory to a file
def log(text)
   puts text
   logfile="/home/weirdbricks/duplicates"+DateTime.now.strftime("%H-%M_%m-%d-%Y")+".log"
   `echo #{text} >> #{logfile}`
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

