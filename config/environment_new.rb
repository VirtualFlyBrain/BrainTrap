DATA_IMAGE_FOLDER = 'http://virtualflybrain.org/data/BrainTrap/site-images90/'
DATA_ACCESS_HASH = true

# Load the Rails application.
require_relative "application"

# Disable host checking
config.hosts = nil 

# Initialize the Rails application.
Rails.application.initialize!
