module TestMain exposing (..)

import Benchmark.Runner exposing (BenchmarkProgram, program)
import ParserBenchmarks


main : BenchmarkProgram
main =
    program ParserBenchmarks.suite
