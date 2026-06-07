#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double *float_array_add_malloc_loop(const double *xs, const double *ys, size_t n) {
  double *out = (double *)malloc(n * sizeof(double));
  if (out == NULL) {
    return NULL;
  }
  for (size_t i = 0; i < n; i++) {
    out[i] = xs[i] + ys[i];
  }
  return out;
}

static double sum_array(const double *xs, size_t n) {
  double s = 0.0;
  for (size_t i = 0; i < n; i++) {
    s += xs[i];
  }
  return s;
}

static double *make_array(size_t n, double offset) {
  double *xs = (double *)malloc(n * sizeof(double));
  if (xs == NULL) {
    return NULL;
  }
  for (size_t i = 0; i < n; i++) {
    xs[i] = (double)(i % 1024) + offset;
  }
  return xs;
}

static uint64_t now_nanos(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

static int parse_size(const char *s, size_t *out) {
  char *end = NULL;
  errno = 0;
  unsigned long long value = strtoull(s, &end, 10);
  if (errno != 0 || end == s || *end != '\0') {
    return 0;
  }
  *out = (size_t)value;
  return 1;
}

int main(int argc, char **argv) {
  if (argc != 6) {
    fprintf(stderr, "usage: float-array-add-c-bench <implementation> <array-size> <samples> <warmups> <batch-size>\n");
    return 2;
  }
  if (strcmp(argv[1], "c.floatArrayAdd.malloc_loop") != 0) {
    fprintf(stderr, "unknown implementation: %s\n", argv[1]);
    return 2;
  }

  size_t n = 0;
  size_t samples = 0;
  size_t warmups = 0;
  size_t batch_size = 0;
  if (!parse_size(argv[2], &n) || !parse_size(argv[3], &samples) || !parse_size(argv[4], &warmups) || !parse_size(argv[5], &batch_size) || batch_size == 0) {
    fprintf(stderr, "invalid numeric argument\n");
    return 2;
  }

  size_t input_count = samples + warmups;
  if (input_count == 0) {
    input_count = 1;
  } else if (input_count > 2) {
    input_count = 2;
  }
  double **xs_inputs = (double **)calloc(input_count, sizeof(double *));
  double **ys_inputs = (double **)calloc(input_count, sizeof(double *));
  if (xs_inputs == NULL || ys_inputs == NULL) {
    fprintf(stderr, "allocation failed\n");
    free(xs_inputs);
    free(ys_inputs);
    return 1;
  }
  for (size_t i = 0; i < input_count; i++) {
    xs_inputs[i] = make_array(n, (double)(i % 251));
    ys_inputs[i] = make_array(n, 1.0 + (double)(i % 251));
    if (xs_inputs[i] == NULL || ys_inputs[i] == NULL) {
      fprintf(stderr, "allocation failed\n");
      for (size_t j = 0; j <= i; j++) {
        free(xs_inputs[j]);
        free(ys_inputs[j]);
      }
      free(xs_inputs);
      free(ys_inputs);
      return 1;
    }
  }

  volatile double checksum = 0.0;
  for (size_t i = 0; i < warmups; i++) {
    for (size_t k = 0; k < batch_size; k++) {
      size_t input_index = (i * batch_size + k) % input_count;
      double *out = float_array_add_malloc_loop(xs_inputs[input_index], ys_inputs[input_index], n);
      if (out == NULL) {
        fprintf(stderr, "allocation failed\n");
        for (size_t j = 0; j < input_count; j++) {
          free(xs_inputs[j]);
          free(ys_inputs[j]);
        }
        free(xs_inputs);
        free(ys_inputs);
        return 1;
      }
      checksum += sum_array(out, n);
      free(out);
    }
  }
  for (size_t i = 0; i < samples; i++) {
    uint64_t start = now_nanos();
    for (size_t k = 0; k < batch_size; k++) {
      size_t input_index = ((warmups + i) * batch_size + k) % input_count;
      double *out = float_array_add_malloc_loop(xs_inputs[input_index], ys_inputs[input_index], n);
      if (out == NULL) {
        fprintf(stderr, "allocation failed\n");
        for (size_t j = 0; j < input_count; j++) {
          free(xs_inputs[j]);
          free(ys_inputs[j]);
        }
        free(xs_inputs);
        free(ys_inputs);
        return 1;
      }
      checksum += sum_array(out, n);
      free(out);
    }
    uint64_t stop = now_nanos();
    printf("%llu\n", (unsigned long long)(stop - start));
  }

  if (isnan((double)checksum)) {
    fprintf(stderr, "unexpected NaN checksum\n");
  }
  for (size_t i = 0; i < input_count; i++) {
    free(xs_inputs[i]);
    free(ys_inputs[i]);
  }
  free(xs_inputs);
  free(ys_inputs);
  return 0;
}
