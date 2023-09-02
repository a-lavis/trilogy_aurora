# ⚠️ Warning

As far as I'm aware, this hasn't been used in production.  Please test before using!

If you use this gem in production, please let me know so I can update this README!

# TrilogyAurora

Modifies [Trilogy](https://github.com/trilogy-libraries/trilogy) to support AWS Aurora failover.

Essentially, the [mysql2-aurora](https://github.com/alfa-jpn/mysql2-aurora) gem but for Trilogy.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add trilogy_aurora

## Usage

In addition to existing initialization options for `Trilogy`, you can now also use the `aurora_max_retry` and `aurora_disconnect_on_readonly` options.

```ruby
Trilogy.new(
  host:             'localhost',
  username:         'root',
  password:         'change_me',
  aurora_max_retry: 5,
  aurora_disconnect_on_readonly: true
)
```

with Rails >= 7.1, in `database.yml`

```yml
development:
  adapter:          trilogy
  host:             localhost
  username:         root
  password:         change_me
  aurora_max_retry: 5
  aurora_disconnect_on_readonly: true
```

From the README of [mysql2-aurora](https://github.com/alfa-jpn/mysql2-aurora):
> There are essentially two methods for handling and RDS Aurora failover. When there is an Aurora RDS failover event the primary writable server can change it's role to become a read_only replica. This can happen without active database connections droppping.
> This leaves the connection in a state where writes will fail, but the application belives it's connected to a writeable server. Writes will now perpetually fail until the database connection is closed and re-established connecting back to the new primary.
>
> To provide automatic recovery from this method you can use either a graceful retry, or an immediate disconnection option.
> ### Retry
>
> Setting aurora_max_retry, mysql2 will not disconnect and automatically attempt re-connection to the database when a read_only error message is encountered.
> This has the benefit that to the application the error is transparent and the query will be re-run against the new primary when the connection succeeds.
>
> It is however not safe to use with transactions
>
> Consider:
>
> * Transaction is started on the primary server A
> * Failover event occurs, A is now readonly
> * Application issues a write statement, read_only exception is thrown
> * mysql2-aurora gem handles this by reconnecting transparently to the new primary B
> * Aplication continues issuing writes however on a new connection in auto-commit mode, no new transaction was started
>
> The application remains un-aware it is now operating outside of a transaction, this can leave data in an inconcistent state, and issuing a ROLLBACK, or COMMIT will not have the expected outcome.
>
> ### Immediate disconnect
>
> Setting aurora_disconnect_on_readonly to true, will cause mysql2 to close the connection to the database on read_only exception. The original exception will be thrown up the stack to the application.
> With the database connection disconnected, the next statement will hit the disconnected error and the application can handle this as it would normally when been disconnected from the database.
>
> This is safe with transactions.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/a-lavis/trilogy_aurora.

## Testing

```shell
# Image build
bin/docker-build

# Run tests
bin/docker-test
```
