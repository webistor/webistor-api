# Webistor API - Version 0.4

## Installing

### Prerequisites

* Install Node
  [From website](http://nodejs.org/)
* Install MongoDB
  [From website](http://www.mongodb.org/)
* Install Node Package Manager
  `sudo chown -R $USER /usr/local`
  `curl http://npmjs.org/install.sh | sh`

### Installation

* Clone repository
  `git clone git@github.com:Tuxion/webistor-api.git`
* Install dependencies
  `cd webistor-api`
  `npm install`
* Install CoffeeScript
  `npm install -g coffee-script`
* Compile CoffeeScript
  `cake build`

## Running

* Start the application.
  `node lib/initialize.js`

## Developing

### Prerequisites

* Install Nodemon
  `npm install -g nodemon`
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
  `npm start`

### Testing

Soon...
