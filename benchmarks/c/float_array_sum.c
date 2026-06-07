#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double float_array_sum_loop(const double *xs, size_t n) {
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
    fprintf(stderr, "usage: float-array-sum-c-bench <implementation> <array-size> <samples> <warmups> <batch-size>\n");
    return 2;
  }
  if (strcmp(argv[1], "c.floatArraySum.loop") != 0) {
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
  double **inputs = (double **)calloc(input_count, sizeof(double *));
  if (inputs == NULL) {
    fprintf(stderr, "allocation failed\n");
    return 1;
  }
  for (size_t i = 0; i < input_count; i++) {
    inputs[i] = make_array(n, (double)(i % 251));
    if (inputs[i] == NULL) {
      fprintf(stderr, "allocation failed\n");
      for (size_t j = 0; j < i; j++) {
        free(inputs[j]);
      }
      free(inputs);
      return 1;
    }
  }

  volatile double checksum = 0.0;
  for (size_t i = 0; i < warmups; i++) {
    for (size_t k = 0; k < batch_size; k++) {
      checksum += float_array_sum_loop(inputs[(i * batch_size + k) % input_count], n);
    }
  }
  for (size_t i = 0; i < samples; i++) {
    uint64_t start = now_nanos();
    for (size_t k = 0; k < batch_size; k++) {
      checksum += float_array_sum_loop(inputs[((warmups + i) * batch_size + k) % input_count], n);
    }
    uint64_t stop = now_nanos();
    printf("%llu\n", (unsigned long long)(stop - start));
  }

  if (isnan((double)checksum)) {
    fprintf(stderr, "unexpected NaN checksum\n");
  }
  for (size_t i = 0; i < input_count; i++) {
    free(inputs[i]);
  }
  free(inputs);
  return 0;
}
