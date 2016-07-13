# HomeLibraryManager

[![Build Status](https://travis-ci.org/cincospenguinos/HomeLibraryManager.svg?branch=master)](https://travis-ci.org/cincospenguinos/HomeLibraryManager)
[![Coverage Status](https://coveralls.io/repos/github/cincospenguinos/HomeLibraryManager/badge.svg?branch=master)](https://coveralls.io/github/cincospenguinos/HomeLibraryManager?branch=master)

This is a simple Sinatra service that helps manage a home library (as in the kind that holds books.) 
It is intended to be simple, low maintenance, and easy to deploy and use. It is also intended to be able
to run alongside any number of other Sinatra services (hence it is built in the [Modular Sinatra fashion.](http://www.sinatrarb.com/intro.html#Modular%20vs.%20Classic%20Style))

## How do I use it?

Simply throw a RESTful request at different URLs registered with the service. The service will always respond with a JSON
string as follows:

```javascript
{
    "successful" : bool // True if the desired operation succeeded, false if it did not
    "results" : [...] // Results of the operation. This is where requested books will be.
    "message" : string // A string that provides extra information where needed, i.e. if the operation is unsuccessful
}
```

### GET '/books'

Returns all the books in the library. You can throw extra parameters at it to select what types of books you
would like to see. Below is the list of possible parameters:

  * author_last --> The author's last name
  * author_first --> The author's first name
  * subject --> What subject a given book belongs to (Literature, Non-Fiction, Philosophy, etc.)
  * title --> The title of a book
  * checked_out --> Whether or not the book is checked out
  * match --> Indicate which parameters must match each other (can be 'all' or 'any' or any above parameter except 'checked_out')

By default, the `match` parameter is set to `all` - that is, the collection of books returned will match all
of the requested parameters. Below are a few examples of this:

```
GET '/books?subject=Philosophy' => returns books on Philosophy
GET '/books?author_last=Hemingway' => returns all books written by Hemingway
GET '/books?subject=Fiction&author_last=Beckett&author_first=Samuel' => returns all fiction written by Samuel Beckett
GET '/books?subject=Fiction&author_last=Beckett&author_first=Samuel&match=all' => same as previous request
```
  
You can also request books that match multiple subjects and multiple authors. To do this, simply use the
'[]' characters after the given parameter name. Note that if you do this with "author_last" and "author_first",
the first author_last parameter will be paired with the first author_first parameter, the second to the second, and
so on.

```
GET '/books?author_last=Plato&subject[]=Philosophy&subject[]=Fiction' => returns all fictional philosophical works of Plato
GET '/books?author_last[]=Adler&author_first[]=Mortimer&author_last[]=Van Doren&author_first[]=Charles' => returns all works by authors Mortimer Adler and Charles Van Doren
GET '/books?author_last=Shakespeare&subject[]=Theater&subject[]=Fiction => returns the theatrical and fictional works of Shakespeare
```

If you set the parameter `match=any`, then the service will return all books that match *any* of the parameters:

```
GET '/books?subject[]=Philosophy&subject[]=Fiction&match=any' => returns all books that are either Philosophy or Fiction
GET '/books?author_last[]=Plato&author_last[]=Aristotle&match=any' => returns all books written by Plato or Aristotle
GET '/books?author_last[]=Plato&author_last[]=Aristotle&subject=Fiction&match=any' => returns all books written by Plato or Aristotle or have a subject of Fiction
``` 

Otherwise, the query will only match the given parameter, like so:
```
GET '/books?subject[]=Philosophy&subject[]=Fiction&author_last=More&author_last=Nietzche&match=subject' => returns all fictional and philosophical works of More and Nietczhe
GET '/books?subject[]=Philosophy&subject[]=Fiction&author_last=More&author_last=Nietzche&match=author_last' => returns all fictional or philosophical works written by both More and Nietczhe
```

If you set the parameter `match` to be anything other than `all` or `any`, then that parameter must exist in the request. So the request 
```GET '/books?subject[]=Fiction&subject[]=Theater&match=author'``` will not work.

### POST '/books'

Add a book to your library using this URL. You must provide it an isbn number, an author, and a title for it to work.
You may add subjects and other authors as you desire.

Examples:

```
POST '/books?author_last=Shakespeare&author_first=William&title=Tempest, The&isbn=978-0-7434-8283-7'
POST '/books?author_last=Shakespeare&author_first=William&title=Tempest, The&isbn=978-0-7434-8283-7&subject=Fiction'
POST '/books?author_last=Shakespeare&author_first=William&title=Tempest, The&isbn=978-0-7434-8283-7&subject[]=Fiction&subject[]=Theater'
```


### DELETE '/books'

Delete a book matching the given ISBN. This does nothing if the book you are attempting to delete doesn't exist.

### GET '/checkout'

Returns all the people who have checked out books from your library. This still needs to be implemented.

### POST '/checkout'

Register that someone is checking out a book. This still needs to be implemented.

### POST '/checkin'

Register that someone is checking in a book. This still needs to be implemented.

## How do I deploy it?

1. Clone this repo into the repository of your choosing
2. Rake within the repository
3. Modify any generated files as requested (library_config.yml should be one of them)
4. Deploy according to your desires.

I don't really want to tell you how you should be deploying this service as it was intended to be taken and
modified according to the needs/desires of those who use it. Regardless, following the above instructions will
ensure that all the files that the service needs will be generated for you to use.

## Contributing

You can contribute by submitting code, submitting a feature/enhancement or submitting a bug.

### Submitting Code

1. Fork this repo
2. Add the bug fix or feature
3. Add test cases in the spec file.
4. ***Add test cases in the spec file!***
5. Submit a pull request with a reference to the bug or feature you patched/implemented.

I'll pull your changes and play around with them. If they work and I like them, then I'll merge them.

### Requesting a Feature

If you would like to recommend a feature, create an issue and prepend "FEATURE" to the issue title. **Please search** before
doing so, as someone else may have requested that feature.

### Filing a Bug

If you would like to submit a bug, create an issue and prepend "BUG" to the issue title. **Please search** before
doing so, as someone else may have reported that bug. 