#  _____ _____ ____ _____ ____        ____        ____  ___   ___  ____
# |_   _| ____/ ___|_   _/ ___|      |  _ \      / ___|/ _ \ / _ \|  _ \
#   | | |  _| \___ \ | | \___ \ _____| |_) |____| |  _| | | | | | | | | |
#   | | | |___ ___) || |  ___) |_____|  _ <_____| |_| | |_| | |_| | |_| |
#   |_| |_____|____/ |_| |____/      |_| \_\     \____|\___/ \___/|____/


# NOTE TO READERS:
# This is a test case, so we'll be exercising advanced features
# provided by DynamoDB. If you're looking for simple examples to start
# from, please check out example.jl in the doc/ folder of this repo.


include("../src/dynamo.jl")

# see runtests.jl for Foo's definition

foo_basic = dynamo_table(Foo, "foo_basic", :a, nothing)
foo_basic_lsi = dynamo_local_index(foo_basic, "foo_basic_indexed_on_b", :b)
foo_basic_gsi = dynamo_global_index(foo_basic, "foo_basic_global_index_on_b_a", :b, :a)

foo_range = dynamo_table(Foo, "foo_range", :a, :b)
foo_range_gsi = dynamo_global_index(foo_range, "foo_range_global_index_on_b_a", :b, :a)


## GET_ITEM

# helper to make get_item_query_dict match get_item's iterface
get_item_dict(table :: DynamoTable, key, range=nothing;
              consistant_read=true, only_returning=nothing :: Union{Void, Array{DynamoReference}}) =
    get_item_query_dict(table, key, range, consistant_read, only_returning)

@test get_item_dict(foo_basic, "asdf") ==
    Dict("TableName" => "foo_basic", "ConsistentRead" => true,
         "Key" => Dict("a" => Dict("S" => "asdf")))

@test get_item_dict(foo_range, "asdf", 3) ==
    Dict("TableName" => "foo_range", "ConsistentRead" => true,
         "Key" => Dict("a" => Dict("S" => "asdf"), "b" => Dict("N" => 3)))

@test get_item_dict(foo_basic, "asdf"; consistant_read=false) ==
    Dict("TableName" => "foo_basic", "ConsistentRead" => false,
         "Key" => Dict("a" => Dict("S" => "asdf")))

@test get_item_dict(foo_basic, "asdf"; consistant_read=false, only_returning=[attr("a")]) ==
    Dict("TableName" => "foo_basic", "ConsistentRead" => false, "ProjectionExpression" => "#1",
         "ExpressionAttributeNames" => Dict("#1" => "a"), "Key" => Dict("a" => Dict("S" => "asdf")))


## BATCH_GET_ITEM

@test batch_get_item_dict([batch_get_item_part(foo_basic, 1, 2)]) ==
    Dict("RequestItems" => Dict("foo_basic" => Dict("ConsistentRead" => true,
                                                    "Keys" => [Dict("a" => Dict("N" => 1)),
                                                               Dict("a" => Dict("N" => 2))])))

@test batch_get_item_dict([batch_get_item_part(foo_range, (1, 2), (3, 4))]) ==
    Dict("RequestItems" => Dict("foo_range" =>
                                Dict("ConsistentRead" => true,
                                     "Keys" => [Dict("a" => Dict("N" => 1), "b" => Dict("N" => 2)),
                                                Dict("a" => Dict("N" => 3), "b" => Dict("N" => 4))])))

@test batch_get_item_dict([batch_get_item_part(foo_basic, 1, 2),
                           batch_get_item_part(foo_range, (1, 2), (3, 4))]) ==
    Dict("RequestItems"=>Dict("foo_basic"=>Dict("Keys"=>[Dict("a"=>Dict("N"=>1)),
                                                         Dict("a"=>Dict("N"=>2))],
                                                "ConsistentRead"=>true),
                              "foo_range"=>Dict("Keys"=>[Dict("a"=>Dict("N"=>1),"b"=>Dict("N"=>2)),
                                                         Dict("a"=>Dict("N"=>3),"b"=>Dict("N"=>4))],
                                                "ConsistentRead"=>true)))


## PUT ITEM

