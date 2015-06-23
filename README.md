# RhinoBird

This is the core platform of RhinoBird project

## Development

Ruby & Sinatra & ActiveRecord stack.

```bash
$ bundle install
$ rake db:migrate
$ rackup
```

This is only server side API for the platform. You need at least the folowlling components to develop the web UI:

1. [rhinobord-web](https://github.com/rhinobird-io/rhinobird-web)

   The web assets of the platform

2. [mock gateway](https://github.com/rhinobird-io/mock-platform)

   A simple non-prodcution service gateway to distribute API requests
   
Check the [wiki](https://github.com/rhinobird-io/rhinobird/wiki) for more detail.

