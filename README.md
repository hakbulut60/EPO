# Enhanced Puma Optimizer (EPO)

Enhanced Puma Optimizer (EPO) is a population-based metaheuristic optimization algorithm developed for continuous optimization problems.

## Main Features

- Adaptive exploration and exploitation
- Momentum-guided exploration
- Multi-candidate exploitation
- Dynamic scoring strategy
- Adaptive step-size reduction

## Paper Status

The related manuscript has been submitted to *Neural Computing and Applications*.

## Usage

```matlab
Npop = 30;
MaxIt = 500;
nD = 30;

lb = -100 * ones(1,nD);
ub = 100 * ones(1,nD);

fobj = @sphere_func;

[BestPos, BestFit, Curve] = EPO(Npop, MaxIt, lb, ub, nD, fobj);
```

## Repository Structure

```text
EPO.m                      Main algorithm
examples/                  Example scripts
benchmark_functions/       Benchmark functions
results/                   Experimental results
docs/                      Documentation
```

## License

MIT License
