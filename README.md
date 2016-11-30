# HomeLibraryManager

[![Build Status](https://travis-ci.org/cincospenguinos/HomeLibraryManager.svg?branch=master)](https://travis-ci.org/cincospenguinos/HomeLibraryManager)
[![Coverage Status](https://coveralls.io/repos/github/cincospenguinos/HomeLibraryManager/badge.svg?branch=master)](https://coveralls.io/github/cincospenguinos/HomeLibraryManager?branch=master)

This is a simple Sinatra service that helps manage a home library (as in the kind that holds books.) 
It is intended to be simple, low maintenance, and easy to deploy and use. It is also intended to be able
to run alongside any number of other Sinatra services (hence it is built in the [Modular Sinatra fashion.](http://www.sinatrarb.com/intro.html#Modular%20vs.%20Classic%20Style))

## How do I use it?

Simply throw an HTTP request at different URLs registered with the service. The service will always respond with a JSON
string as follows:

```
{
    "successful" : bool // True if the desired operation succeeded, false if it did not
    "results" : [...] // Results of the operation. This is where requested books will be.
    "message" : string // A string that provides extra information where needed, i.e. if the operation is unsuccessful
}
```

### GET '/books'

This method will return all of the books that match all of the given parameters. Permitted parameters
are `last_name`, `subject`, and `title`. By default only a summary of each book is returned.
You can request detailed information by passing `summary=false` as a parameter as well. Below
are some examples.

```
GET '/books' => returns all the books in the library
GET '/books?summary=false' => returns detailed information about all the books in the library
GET '/books?last_name=Dostoevsky' => returns all books written by Dostoevsky
GET '/books?last_name=Dostoevsky&subject=fiction' => returns all fiction works by Dostoevsky
GET '/books?last_name=Dostoevsky&subject[]=fiction&subject[]=philosophy' => returns all works by Dostoevsky that are both fictional and philosophical
```

### POST '/books'

Add a book to the library. The required parameters are `authors`, `title`, and `isbn`. Optional
parameters are `subjects`. This method will not save anything if the proper parameters do not
exist.

When submitting an author in `authors`, the service expects the user to provide the author's names
separated with a comma. Thus `authors[]=More,Thomas` is acceptable, but `authors[]=Thomas More`
is not. If the user submits `authors[]=Thomas,More`, then the book's author will be listed as 
"More Thomas".

If there is no first name for a given author, then simply pass `authors[]=last_name,`.

```
POST '/books?authors[]=More,Thomas&isbn=9781593082444&title=Utopia' => Adds Utopia by Thomas More
POST '/books?authors[]=More,Thomas&isbn=9781593082444&title=Utopia&subjects[]=philosophy' => Adds Utopia by Thomas More with subject "philosophy"
POST '/books?authors[]=Thomas,More&isbn=9781593082444&title=Utopia' => Adds Utopia by More Thomas
POST '/books?authors[]=More,Thomas&title=Utopia' => Adds nothing
```

### PUT '/books'

Update information about a book that exists in the library. Requires the parameter `isbn`, with optional parameters
of `authors` and `subjects`. The same expectations apply for the authors parameter for this method as with `POST '/books'`.
You can remove a piece of information from a book using the `remove` parameter. The default for `remove` is `false`.

```
PUT '/books?isbn=9781593082444&authors[]=Cool,Joe' => Adds the author 'Joe Cool' to the book
PUT '/books?isbn=9781593082444&subjects[]=Fiction' => Adds the subject 'Fiction' to the book
PUT '/books?isbn=9781593082444&subjects[]=Fiction&subjects[]=Philosophy&remove=true' => Removes the subjects "Fiction" and "Philosophy" from the book
```

### DELETE '/books'

Delete a specific book from the library. Requires only a list of `isbns` to delete.

```
DELETE '/books?isbns[]=9781593082444' => Removes the book matching the provided ISBN
DELETE '/books?isbns[]=9781593082444&isbns[]=9780743297332' => Removes the books matching the provided ISBNs
```

### GET '/checkout'

Browse who has checked out what books from the library. Acts just like `GET '/books'`. Valid parameters are `last_name`
and `first_name`.

### POST '/checkout'

Indicates to the service that someone is checking out a book. Requires `isbn`, `last_name` and `first_name`. Optional
parameters are `email_address` and `phone_number`.

### POST '/checkin'

Checks in a book that has been checked out. Requires parameter `isbn`.

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
