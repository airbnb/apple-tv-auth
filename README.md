# Apple TV Authentication Example

This is an example authentication server for an Apple TV or other device that
doesn't lend itself to password entry. Check out _insert link to blog post_ for
details about the workflow implemented here.

Much of the basic Sinatra/Warden implementation is based on Steve Klise's
excellent example: https://github.com/sklise/sinatra-warden-example. The most
interesting things to look at are `auth_token.rb` and the `:nonce` Warden
strategy in `app.rb`.
