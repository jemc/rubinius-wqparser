rubinius-wqparser
=================

Adapter for using https://github.com/whitequark/parser as Rubinius' parser.

## How Does It Work?

Conceptually, this adapter replaces [rubinius-processor](https://github.com/rubinius/rubinius-processor) so that [parser](https://github.com/whitequark/parser) can replace [rubinius-melbourne](https://github.com/rubinius/rubinius-melbourne) to generate the same [rubinius-ast](https://github.com/rubinius/rubinius-ast) nodes from a given source file or string.  The resulting AST tree can be compiled to rubinius bytecode by the [rubinius-compiler](https://github.com/rubinius/rubinius-compiler) to be executed by the [Rubinius](https://github.com/rubinius/rubinius) runtime.

## Is Is Complete?

Not all specs pass yet.  See the failure tags for specs known to be failing in the `spec/tags` directory.

## How Is It Tested?

This adapter is tested against three sets of specs:

1. `spec` - The same set of specs that [rubinius-melbourne](https://github.com/rubinius/rubinius-melbourne) tests itself with.
2. `spec/wq/parser_spec.rb` - A set of specs automatically generated from `spec/wq/test_parser.rb`, which "writes" specs based on test cases taken from [the specs for parser](https://github.com/whitequark/parser/blob/master/test/test_parser.rb) (see `spec/wq/test_parser.rb` for details).
3. `spec/added` - Any other specs created to prevent regression of various other behaviors encountered that are not covered by the above two sets of specs.

In each case, a source string is parsed and converted to a sexp representation, which is then compared to an expected sexp.

Specs that are known to be failing can be found in `spec/tags`, which mirrors the `spec` directory with files full of failure tags.

You can run all of the specs known to be passing with:
```shell
mspec spec -G fails
```

You can run all specs (including failing ones) with:
```shell
mspec spec
```

See `mspec --help` for more details about its usage.

