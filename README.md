# Team Work

Advanced, awesome, cutting-age teamwork software.

## Technology

1. Web Component
2. Polymer
3. Docker
4. Microservices

## Development

### Catch Up

We use Polymer, Ruby, Sinatra, ActiveRecord for current prototype phase.
It is recommended to read some materials about them, but not too much.
Try and learn them by some tasks in our project, send merge request for review. Don't be afraid of mistakes.

### Getting Started

1. Require Ruby with bundle gem installed, Bower, latest Google Chrome.

2. Tips:
    * You may find [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv) good for manage your ruby versions
    * It is recommended to use Linux or Mac OS X for development.

3. Build & run
    ```bash
    $ cd public
    $ bower install
    $ cd ..
    $ bundle install
    $ rake db:migrate
    $ shotgun # shotgun will automatically apply any changes for your code, just refresh the page
    ```
4. Once you change database, create database migrations:
    ```bash
    $ rake db:create_migration NAME=xxx
    ```

5. If you want to fill the database by sample data:
    ```bash
    $ rake db:populate # Be careful, it will destroy your database and recreate it!!
    ```

6. Check all rake tasks:
    ```bash
    $ rake -T
    ```
