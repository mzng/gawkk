#********************************************************************************
#Copyright 2009 Octazen Solutions
#All Rights Reserved
#
#You may not reprint or redistribute this code without permission from Octazen Solutions.
#
#WWW: http://www.octazen.com
#Email: support@octazen.com
#********************************************************************************

$:.unshift(File.dirname(__FILE__))

# This is the entrypoint to the library

module Octazen
  #This will hold hash of domain name to importer class name
  DOMAIN_IMPORTERS = {}
end


require 'abiconfig'
require 'abimporter'


# Dynamically load available importers

def load_if_exist (path)
  if File.exist?(File.dirname(__FILE__)+'/'+path)
    Octazen::Logging.debug("Loading #{path}")
    require(path)
  end
end

#Contacts Importer Bundle 1
load_if_exist('hotmail.rb')
load_if_exist('aol.rb')
load_if_exist('gmail.rb')
load_if_exist('yahoo.rb')
load_if_exist('linkedin.rb')

#Contacts Importer Bundle 3
load_if_exist('portablecontacts.rb')
load_if_exist('plaxo.rb')
