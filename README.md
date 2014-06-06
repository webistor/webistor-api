# Webistor API - Version 0.4 Dev

## Installing (Linux Debian)

### Prerequisites

* Install build tools
  `sudo apt-get install gcc make build-essential g++`
* Install Node
  `sudo apt-get install nodejs-legacy`
  or [From website](http://nodejs.org/)
* Install MongoDB Version 2.6 or higher
  [From website](http://www.mongodb.org/)
* Install Node Package Manager
  `curl https://www.npmjs.org/install.sh | sudo sh`

### Installation

* Clone repository
  `git clone git@github.com:Tuxion/webistor-api.git`
* Install dependencies
  `cd webistor-api`
  `npm install`
* Compile CoffeeScript
  `cake build`

## Running

* Start the application.
  `cake start` or `cake -w start` to restart automatically on changes.

## Development

### Prerequisites

* Install [git flow](https://github.com/nvie/gitflow)
  `sudo apt-get install git-flow`
  Or try: [Install guide](https://github.com/nvie/gitflow/wiki/Installation)
* Initialize git flow
  `cd webistor-api`
  [`git flow init`](https://github.com/nvie/gitflow/wiki/Command-Line-Arguments#git-flow-init--fd)

### Coding

* Create your feature branch
  [`git flow feature start <name>`](https://github.com/nvie/gitflow/wiki/Command-Line-Arguments#git-flow-feature-start--f-name-base)
* Watch CoffeScript
  `cake watch`
* Watch JavaScript
  `cake -w start`
* **Don't commit your local environment settings**:
  [How to ignore versioned files](https://help.github.com/articles/ignoring-files#ignoring-versioned-files)

### Testing

Write your tests in `/test/<path>`. The convention is to make <path> the same as the path
to the file that you're testing in `/src/<path>`. Generic tests may be placed
in `test/<name>.coffee`, but should be avoided.

More about creating tests can be found in the documentation below. Tests look like this:

```coffeescript
describe "Mocha", ->
  it "should be able to describe stuff", ->
    describe.must.exist()
```

Run tests using `cake test` or `cake --watch test` to continuously test.

### Documentation

#### Application

* [Lodash](http://lodash.com/docs): Utility library used.
* [CoffeeScript](http://coffeescript.org/): Source code language.
* [Node](http://nodejs.org/api/): JavaScript built-ins.
* [Express](http://expressjs.com/api.html): Framework used.
* [Mongoose](http://mongoosejs.com/docs/api.html): Database abstraction layer used.
* [MongoDB](http://docs.mongodb.org/manual/): Database used.
* [Bluebird](https://github.com/petkaantonov/bluebird/blob/master/API.md): Promise library used.
* [Node Restful](https://github.com/baugarten/node-restful): Mongoose exposure to REST helpers.
* [Node Logging](https://github.com/Monwara/node-logging): Logging library used.
* [Node bcrypt](https://github.com/ncb000gt/node.bcrypt.js): Hashing and cryptology library used.
* [Node rand-token](https://github.com/sehrope/node-rand-token): Token generating library.

#### Testing

* [Mocha](http://visionmedia.github.io/mocha/#getting-started): Test runner and describer
* [Must](https://github.com/moll/js-must/blob/master/doc/API.md): BDD Assertion library.
* [Supertest](https://github.com/visionmedia/supertest): HTTP Assertion library.

### Planned features

* All features from the [current stable](https://github.com/Tuxion/webistor-api/tree/0.4).
* Sharing of entries.
* [Elastic Search](http://www.elasticsearch.org/) with the
  [Node client](https://github.com/phillro/node-elasticsearch-client).
