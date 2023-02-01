const express = require('express');
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const session = require('express-session');
const app = express();

// Use sessions for tracking user logins
app.use(session({
  secret: 'keyboard cat',
  resave: true,
  saveUninitialized: true
}));
app.use(passport.initialize());
app.use(passport.session());

// Set up the Google OAuth2 strategy for Passport
passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: '/auth/google/callback'
}, (accessToken, refreshToken, profile, done) => {
  return done(null, profile);
}));

// Serialize user for storing in the session
passport.serializeUser((user, done) => {
  done(null, user);
});

// Deserialize user from the session
passport.deserializeUser((user, done) => {
  done(null, user);
});

// Endpoint for handling the OAuth2 redirect from Google
app.get('/auth/google', passport.authenticate('google', {
  scope: ['profile']
}));

// Endpoint for handling the OAuth2 callback from Google
app.get('/auth/google/callback', passport.authenticate('google', {
  failureRedirect: '/',
  successRedirect: '/home'
}));

// Endpoint for serving the protected "home" page
app.get('/home', (req, res) => {
  if (!req.user) {
    return res.redirect('/');
  }
  res.send(`Welcome, ${req.user.displayName}!`);
});

// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
});
