# DynamoDB.jl

TL;DR: Julia interface to AWS DynamoDB using [AWSCore.jl](https://github.com/samoconnor/AWSCore.jl)

## Fork details

This code is a fork of [Conning/DynamoDB.jl](https://github.com/Conning/DynamoDB.jl)
which applies Julia 0.5 compatibility updates to the original codebase,
[dls/DynamoDB](https://github.com/dls/DynamoDB.jl), which now appears stale.

This fork replaces the use of [JuliaCloud/AWS.jl](https://github.com/JuliaCloud/AWS.jl)
with [samoconnor/AWSCore.jl](https://github.com/samoconnor/AWSCore.jl) whose
master branch is fully compatible with Julia 0.5.

## Installation and testing

You will require the `master` branch of [samoconnor/AWSCore.jl](https://github.com/samoconnor/AWSCore.jl).
Configuration of AWS credentials is achieved according to the documentation for
`aws_config` in `AWSCore.jl`. Tests can be run in the usual way, though online
testing of DynamoDB requires you to create a DynamoDB table with name `JULIA_TESTING`
a primary key `id` of string type, and a secondary index `order` of number type.

# Original documentation

Linux, OSX: [![Build Status](https://travis-ci.org/dls/DynamoDB.jl.svg?branch=master)](https://travis-ci.org/dls/DynamoDB.jl)

Windows: [![Build status](https://ci.appveyor.com/api/projects/status/qwlfcnnx0i1cti11?svg=true)](https://ci.appveyor.com/project/dls/dynamodb-jl)

(Windows support will be a while -- it's an issue loading the crypto shared object)

[![codecov.io](http://codecov.io/github/dls/DynamoDB.jl/coverage.svg?branch=master)](http://codecov.io/github/dls/DynamoDB.jl?branch=master)

Pure julia DynamoDB
bindings. [DynamoDB](https://aws.amazon.com/dynamodb/details/) is a
proprietary NoSQL database offered by amazon which provides very [cost
effective](https://aws.amazon.com/dynamodb/pricing/), typed,
javascriptish document storage.

New or prospective users should be warned that while DynamoDB provides
fairly expressive row-level operations (conditional writes, atomic
increment, etc), it does have a learning curve for those used to
regular databases due to its **complete lack of aggregate
functions**... this is the cost of scaling if you will, since these
become expensive as your data grows.

# Beta notice

This library was released on October 30th, 2015. Although I've tried
my best to avoid it, It no-doubt contains bugs, and should not (yet)
be used for mission critical work. Or at least not without you reading
this and strongly considering some end-to-end tests.

# Example

```julia
using DynamoDB

type DynamoExample
     id
     order
     int_to_update
end

const table = dynamo_table(DynamoExample, "JULIA_TESTING", :id, :order; env=env)

put_item(table, DynamoExample("string-based-id", 1, 10))
put_item(table, DynamoExample("string-based-id", 2, 100))
put_item(table, DynamoExample("string-based-id2", 1, 1000))

@show get_item(table, "string-based-id", 1).int_to_update # --> 10

update_item(table, "string-based-id", 1,
            set(attr("int_to_update"), attr("int_to_update") + 1)) # increments int_to_update

@show get_item(table, "string-based-id", 1).int_to_update # --> 11

update_item(table, "string-based-id", 1,
            set(attr("int_to_update"), attr("int_to_update") + 1),
            conditions=attr("int_to_update") == 10) # will fail to increment -- int_to_upate is 11

query(table, "string-based-id", between(attr("order"), 0, 10)) # gets us those first two elements
```

See the [integration
test](https://github.com/dls/DynamoDB.jl/blob/master/test/integration_tests.jl)
for more examples.
