# ExBanking

## Description
Simple banking OTP application using GenServers

## Considerations
During this project I am not considering *exchange rates* for different currencies. That is something that can be achieved with the package https://github.com/kipcole9/money but I didn't use it because of simplicity. Also, the spec types require a `integer` or `float` type, which is not the type returned by packages like `ex_money`.

If not using `Money` structs, I usually deal with `Decimal` structs instead of floats to avoid inconsistencies with with math operations. Some of that is explained here: https://0.30000000000000004.com/

Usually when sending money from one user to another we should use **transactions**, a feature provided by databases like Postgres. With that, we make sure that all operations are handled correctly, if not all changes rollback to the initial state before the beginning of the operation.
In Elixir we could use things like `Ecto.Multi`.

In this example we are not using any database, so we make this simpler.

I could have used mocks for tests. It would have been easier.

To test the project do `mix test`.

## How to interact with this project

First, *create* a new user:

`ExBanking.create_user("manu")`

Note that the program won't let you introduce invalid or repeated values.

Then you can *deposit* money into the user account:

`ExBanking.deposit("manu", 100, "USD")`

If the user doesn't have an account of a certain currency it will create it automatically.

You can also *withdraw* money from that account in the currency you need. Note that if you don't have an account in *EUR*, for example, you won't be able to *withdraw* money to avoid inconsistencies in data. Also, it will be impossible to *withdraw* more money than what you currently have.

`ExBanking.withdraw("manu", 45, "USD")`

You can *send* money to another user, as long as the users exist, the money is enough and the values are valid in format. The sender will only send money from an account of a currency he/she owns. If the sender doesn't have an `EUR` account the program won't allow the transaction. If the receiver doesn't have an account in certain currency it will be created automatically.

`ExBanking.send("manu", "stanley", 50, "USD")`

It is possible to *get balance* of a user for a certain currency.

`ExBanking.get_balance("manu", "USD")`


