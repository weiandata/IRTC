# Streaming engine — threading, interrupts, BLAS (SP5.1)

- **Interrupts**: the C++ E-step kernel processes persons in blocks of 100,000 and
  calls `Rcpp::checkUserInterrupt()` on the main thread between blocks. Ctrl-C
  therefore interrupts within roughly one block. Worker threads never call the R
  API (they touch only raw arrays).

- **Determinism**: results are bit-identical for a fixed `n_threads` (repeat-stable).
  Across different `n_threads` they agree to ~1e-8: the kernel partitions persons
  across threads and sums per-thread partial statistics, so the reduction order
  (hence floating-point rounding) depends on the thread count. This is expected and
  harmless; use `method="grid"` if bit-identical-across-thread-count output is required.

- **BLAS oversubscription**: the engine parallelizes the E-step with `std::thread`
  (default = all cores). If the system BLAS is also multithreaded, nested
  parallelism can oversubscribe the cores and slow things down. For large runs,
  cap BLAS threads during estimation, e.g.

  ```r
  RhpcBLASctl::blas_set_num_threads(1)   # or: Sys.setenv(OMP_NUM_THREADS = 1)
  ```

  The engine's own M-step uses small per-item BLAS calls whose cost is independent
  of N, so limiting BLAS threads does not hurt the dominant E-step.
