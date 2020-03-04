**Update:** On March 3, 2020 Airbnb sunset the Airbnb Apple TV app.

# Apple TV Authentication Example

This is an example authentication server for an Apple TV or other device that
doesn't lend itself to password entry. Check out https://medium.com/airbnb-engineering/apple-tv-authentication-a156937ea211#.yyj7id33m for
details about the workflow implemented here.

Much of the basic Sinatra/Warden implementation is based on Steve Klise's
excellent example: https://github.com/sklise/sinatra-warden-example. The most
interesting things to look at are `auth_token.rb` and the `:nonce` Warden
strategy in `app.rb`.

## Demo Instructions

1. Make sure you have Redis running locally: `brew install redis; redis-server`
2. Install gems: `bundle install`
3. Start the app: `rackup`
4. Navigate to <a href=http://localhost:9292>localhost:9292</a>.
5. You'll see the short code displayed as you would on an Apple TV.
6. In another browser or private window open <a href=http://localhost:9292>localhost:9292/authorize</a>.
7. Login as admin/admin.
8. Enter the short code in the authorization box and submit it.
9. Return to your first window and see that it has been successfully logged in.
