# mpi4py Examples

Code examples that illustrate the use of message passing in python using the mpiy4pi library.

## Forest fire simulation

From the **home directory** of the demo-g1 user on the head node of a CSinParallel Raspberry Pi cluster, you can get to this example like this:

```sh
cd CSinParallel/mpi4py-examples/fire
```

From any directory on the head node of the cluster, you can do this:

```sh
cd  ~/CSinParallel/mpi4py-examples/fire
```

The folder called `fire` has a simple simulation of the spread of a wildfire in a forest.

- `fire_sequential_once.py` runs a single model of a fire starting from one tree and burning until it is out.

- `fire_sequentail_simulate.py` runs many of the above single model cases for many 'trials' and averages the results to get a reasonable overall behavior of a fire at different thresholds of probability that fire will spread from one tree to another.

- `fire_mpi_simulate.py` does the same simulation as the above sequential version, but uses parallelism to split the number of trials among processes.

## Drug design simulation

From any directory on the head node of the cluster, you can do this:

```sh
cd  ~/CSinParallel/mpi4py-examples/drug-design
```

The folder called `drug-design` contains two versions of a simple model for matching ligands to proteins.

- `dd_mpi_dynamic.py` uses dynamic load balancing, assigning a new ligand to each process after it finishes one.

- `dd_mpi_equal_chunks.py` splits the work equally and assigns every process the same number of ligands.

## How to experiment with each example

See separate README.md and corresponding README.pdf files inside each directory for instructions about running each example and what you can learn about particular interesting phenomena regarding how each of these examples use parallelism to improve the performance of the simulation.
