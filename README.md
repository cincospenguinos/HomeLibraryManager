# HomeLibraryManager

[![Build Status](https://travis-ci.org/cincospenguinos/HomeLibraryManager.svg?branch=master)](https://travis-ci.org/cincospenguinos/HomeLibraryManager)
[![Coverage Status](https://coveralls.io/repos/github/cincospenguinos/HomeLibraryManager/badge.svg?branch=master)](https://coveralls.io/github/cincospenguinos/HomeLibraryManager?branch=master)

This is a simple Sinatra service that helps manage a home library (as in the kind that holds books.) 
It is intended to be simple, low maintenance, and easy to deploy and use. It is also intended to be able
to run alongside any number of other Sinatra services (hence it is built in the [Modular Sinatra fashion.](http://www.sinatrarb.com/intro.html#Modular%20vs.%20Classic%20Style))

## How do I use it?

Simply throw a RESTful request at different URLs registered with the service. The service will always respond with a JSON
string as follows:

```
{
    "successful" : bool // True if the desired operation succeeded, false if it did not
    "results" : [...] // Results of the operation. This is where requested books will be.
    "message" : string // A string that provides extra information where needed, i.e. if the operation is unsuccessful
}
```

### How this will work

I'm thinking that we can setup a few different heirarchies for different queries.

* get '/books' will return all the books
    * Including search parameters narrows down the search. The search will always use
    the AND operator.
    * Permitted parameters:
        * summary - boolean. Default: true. Determines whether the service will return a summary
        or not
        * last_name - string. Last name of the author
        * subject - string. Books that have a given subject

## Contributing

You can contribute by submitting code, submitting a feature/enhancement or submitting a bug.

### Submitting Code

1. Fork this repo
2. Add the bug fix or feature
3. Add test cases in the spec file
4. **Add test cases in the spec file**
5. Submit a pull request with a reference to the bug or feature you patched/implemented.

I'll pull your changes and play around with them. If they work and I like them, then I'll merge them.

### Requesting a Feature

If you would like to recommend a feature, create an issue and prepend "FEATURE" to the issue title. **Please search** before
doing so, as someone else may have requested that feature. If the feature you want is already listed, simply comment on it
mentioning that that's a feature you would like to see as well.

### Filing a Bug

If you would like to submit a bug, create an issue and prepend "BUG" to the issue title. **Please search** before
doing so, as someone else may have reported that bug. 
