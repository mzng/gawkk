# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_gawkk_session',
  :secret      => '9892c30ea929aaabe031059c1e8f38b0dbdb5bc34d6ac0a497211263c896c75529f842af247612bce38477b9280790092bbf5f4c725540857f0af5173dab67af'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
