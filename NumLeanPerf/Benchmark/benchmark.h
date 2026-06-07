#ifndef NUMLEANPERF_BENCHMARK_H
#define NUMLEANPERF_BENCHMARK_H

#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

static uint64_t numleanperf_now_nanos(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

static int numleanperf_parse_size(const char *s, size_t *out) {
  char *end = NULL;
  errno = 0;
  unsigned long long value = strtoull(s, &end, 10);
  if (errno != 0 || end == s || *end != '\0') {
    return 0;
  }
  *out = (size_t)value;
  return 1;
}

static void numleanperf_black_box_array(const double *xs, size_t n) {
  __asm__ __volatile__("" : : "r"(xs), "r"(n) : "memory");
}

#endif
