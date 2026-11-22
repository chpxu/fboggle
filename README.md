# fBoggle

A Fortran program which finds every English word possible in a grid of $N \times N$ letters. It is basically an automatic version of Boggle and is not affiliated with Boggle or Netflix.

This program is threaded using OpenMP, though unless you're doing extremely large grids the performance impact will be minor.

To do the word search, a depth-first search is performed on the grid of letters. Each thread will start with an available tile and dynamically continue until every cell has been visited. Every possible combination is checked against a dictionary and if it is a match, the word is appended to a thread's copy of found words, and each thread keeps track of its own progress etc.

At the end, the final array of words is merged from all threads, and then the array is sorted alphabetically and deduped, the output is written into a file `found.txt`.


## Building and Using

This project requires:

- OpenMP
- Fortran compiler (gfortran, ifx/ifort). Tested on F2008 standard.

It is preferred to build with `CMAKE>=3.27` or `CMAKE>=4.x` (tested with v4) though Makefile is supported. In the project root, run

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
export OMP_NUM_THREADS=N # set N to an integer
./build/fboggle <path/to/dictionary.txt> <path/to/params.txt>
```

A default English dictionary is provided in `src/words_alpha.txt`, provided from [this GitHub repo](https://github.com/dwyl/english-words/blob/master/words_alpha.txt). The program looks for `words_alpha.txt` by default in the same folder as the binary. Similarly, example `params.txt` is supplied in the `examples` directory.

## Development

```sh 
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
```

## Roadmap

- Comprehensive examples and stress tests/benchmarks
- Support for multi-letter tiles such as `qu` like in the real game, but extended beyond just `qu`
- Improved output, e.g. showing the path in the grid alongside the word


