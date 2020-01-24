# Contributing

## Testing

This library includes spec tests written in [rspec](https://rspec.info). To run them

```
gem install rspec
rspec spec
```

It also uses the `wash validate` command against an example plugin for integration testing. To run
it [install Wash](https://puppetlabs.github.io/wash/getting_started), then run
```
gem build wash.gemspec
gem install wash-*.gem
wash validate examples/mock_docker.rb
```
