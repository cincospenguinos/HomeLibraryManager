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
  * match --> Indicate whether to match all of the given parameters or any of the given parameters

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

Example:

```
DELETE '/books?isbn=978-0-7434-8283-7' => removes The Tempest by Shakespeare from the library
```

### GET '/checkout'

Returns all the people who have checked out books from your library. The available parameters are

* last_name --> Last name of the person who borrowed the book
* first_name --> First name of the person who borrowed the book
* phone_number --> Phone number of the person who borrowed the book
* email_address --> Email address of the person who borrowed the book
* checked_out --> Whether or not you want all of the books they have checked out

Submitting a GET request at this URL with any of those parameters will return all of the people who
match all of the provided parameters as well as all the books they have ever checked out. Below are some examples:

```
GET '/checkout' => returns everyone who checked out a book and what books they checked out a book and their books
GET '/checkout?last_name=Doe' => returns everyone with the last name of "Doe" who checked out a book and their books
GET '/checkout?last_name=Doe&first_name=Jane' => returns everyone with the name "Jane Doe" who checked out a book and their books
GET '/checkout?phone_number=KL5-3226' => returns everyone who checked out a book with that phone number
GET '/checkout?last_name=Doe&checked_out=true' => returns everyone with the last name "Doe" who checked out a book and only the books that are still checked out
GET '/checkout?last_name=Doe&first_name=Jane&checked_out=false' => returns everyone with the name of "Jane Doe" who checked out a book and the books they have returned.
```

Remember that the only required parameters to be in the database are first_name and last_name. If you search for borrowers
by phone number or email address, only the people who had either of those parameters included will show up in your searches.
So if Jane Doe didn't provide a phone number when you added her to the system, and later you tried to find her by using
the phone number you have for her, you'll be out of luck.

### POST '/checkout'

Register that someone is checking out a book. This still needs to be implemented.

### POST '/checkin'

Register that someone is checking in a book. This still needs to be implemented.

## How do I deploy it?

1. Clone this repo into the directory of your choosing
2. Rake within the repository
3. Modify any generated files as requested (library_config.yml should be one of them)
4. Deploy according to your web server's configuration.

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