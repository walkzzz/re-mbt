#ifdef __cplusplus
extern "C" {
#endif

#include "moonbit.h"
#include "moonbit_simd.h"

#ifdef _MSC_VER
#define _Noreturn __declspec(noreturn)
#endif

#if defined(__clang__)
#pragma clang diagnostic ignored "-Wshift-op-parentheses"
#pragma clang diagnostic ignored "-Wtautological-compare"
#endif

MOONBIT_EXPORT _Noreturn void moonbit_panic(void);
MOONBIT_EXPORT void *moonbit_malloc_array(enum moonbit_block_kind kind,
                                          int elem_size_shift, int32_t len);
int memcmp(const void *s1, const void *s2, size_t n);
MOONBIT_EXPORT int moonbit_val_array_equal_sized(const void *lhs,
                                                 const void *rhs,
                                                 int32_t elem_size);
MOONBIT_EXPORT moonbit_string_t moonbit_add_string(moonbit_string_t s1,
                                                   moonbit_string_t s2);
MOONBIT_EXPORT void moonbit_unsafe_bytes_blit(moonbit_bytes_t dst,
                                              int32_t dst_start,
                                              moonbit_bytes_t src,
                                              int32_t src_offset, int32_t len);
MOONBIT_EXPORT moonbit_string_t moonbit_unsafe_bytes_sub_string(
    moonbit_bytes_t bytes, int32_t start, int32_t len);
MOONBIT_EXPORT int32_t moonbit_unsafe_val_array_blit(void *dst,
                                                     int32_t dst_offset,
                                                     void *src,
                                                     int32_t src_offset,
                                                     int32_t len,
                                                     int32_t elem_size);
MOONBIT_EXPORT int32_t moonbit_unsafe_ref_array_blit(void *dst,
                                                     int32_t dst_offset,
                                                     void *src,
                                                     int32_t src_offset,
                                                     int32_t len);
MOONBIT_EXPORT void moonbit_println(moonbit_string_t str);
MOONBIT_EXPORT moonbit_bytes_t *moonbit_get_cli_args(void);
MOONBIT_EXPORT void moonbit_runtime_init(int argc, char **argv);
MOONBIT_EXPORT void moonbit_drop_object(void *);
// Slow paths of the inlined value-enum retain/release below (defined in
// runtime.c). Internal helpers, so declared here rather than in the public
// moonbit.h; reached only when a value's current variant carries references.
MOONBIT_EXPORT void moonbit_incref_value_enum_loop(void *p);
MOONBIT_EXPORT void moonbit_decref_value_enum_loop(void *p);
MOONBIT_EXPORT int32_t moonbit_utf16_len_from_utf8(moonbit_bytes_t src,
                                                   int32_t src_offset,
                                                   int32_t src_length);
MOONBIT_EXPORT int32_t moonbit_utf8_decode_into_utf16(
    moonbit_bytes_t src, int32_t src_offset, int32_t src_length,
    moonbit_string_t dst, int32_t dst_offset);
MOONBIT_EXPORT int32_t moonbit_utf8_decode_lossy_into_utf16(
    moonbit_bytes_t src, int32_t src_offset, int32_t src_length,
    moonbit_string_t dst, int32_t dst_offset);
MOONBIT_EXPORT int32_t moonbit_utf8_len_from_utf16(moonbit_string_t src,
                                                   int32_t src_offset,
                                                   int32_t src_length);
MOONBIT_EXPORT int32_t moonbit_utf8_encode_from_utf16(
    moonbit_string_t src, int32_t src_offset, int32_t src_length,
    moonbit_bytes_t dst, int32_t dst_offset);

#if !defined(_WIN64) && !defined(_WIN32)
void *malloc(size_t size);
void free(void *ptr);
#define libc_malloc malloc
#define libc_free free
#endif

// several important runtime functions are inlined
static void *moonbit_malloc_inlined(size_t size) {
  struct moonbit_object *ptr = (struct moonbit_object *)libc_malloc(
      sizeof(struct moonbit_object) + size);
  Moonbit_init_dynamic_rc(ptr, moonbit_BLOCK_KIND_REGULAR);
  return ptr + 1;
}

#define moonbit_malloc(obj) moonbit_malloc_inlined(obj)
#define moonbit_free(obj) libc_free(Moonbit_object_header(obj))

#define MOONBIT_RC_COUNT_UNIT ((int32_t)(1u << MOONBIT_RC_COUNT_SHIFT))
#define raw_rc_is_dynamic(rc) ((int32_t)(rc) >= MOONBIT_RC_COUNT_UNIT)
#define raw_rc_is_shared(rc) ((int32_t)(rc) >= (MOONBIT_RC_COUNT_UNIT * 2))

extern const uint32_t *moonbit_layout_table;

static void moonbit_incref_inlined(void *ptr) {
  struct moonbit_object *header = Moonbit_object_header(ptr);
  int32_t const rc = header->rc;
  if (raw_rc_is_dynamic(rc)) {
    Moonbit_increase_rc_count(header);
  }
}

#define moonbit_incref moonbit_incref_inlined

static void moonbit_decref_inlined(void *ptr) {
  struct moonbit_object *header = Moonbit_object_header(ptr);
  int32_t const rc = header->rc;
  if (raw_rc_is_shared(rc)) {
    header->rc = rc - MOONBIT_RC_COUNT_UNIT;
  } else if (raw_rc_is_dynamic(rc)) {
    moonbit_drop_object(ptr);
  }
}

#define moonbit_decref moonbit_decref_inlined

// Value-enum retain/release: inline the cheap "does the current variant carry
// references?" test (a header read + class compare) so scalar-tag moves pay no
// call, and delegate the reference-walking loop to the out-of-line slow path in
// runtime.c. Mirrors the moonbit_incref/decref fast/slow split above.
static inline void moonbit_incref_value_enum_inlined(void *p) {
  if (Moonbit_header_layout_class(*(uint32_t *)p) ==
      MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED)
    moonbit_incref_value_enum_loop(p);
}

#define moonbit_incref_value_enum moonbit_incref_value_enum_inlined

static inline void moonbit_decref_value_enum_inlined(void *p) {
  if (Moonbit_header_layout_class(*(uint32_t *)p) ==
      MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED)
    moonbit_decref_value_enum_loop(p);
}

#define moonbit_decref_value_enum moonbit_decref_value_enum_inlined

#define moonbit_unsafe_make_string moonbit_make_string

#if defined(MOONBIT_V128_NEON)
#define Moonbit_v128_make(lo, hi)                                             \
  vreinterpretq_u8_u64(                                                       \
      vcombine_u64(vcreate_u64((uint64_t)(lo)), vcreate_u64((uint64_t)(hi))))
#define Moonbit_v128_lo(v) vgetq_lane_u64(vreinterpretq_u64_u8(v), 0)
#define Moonbit_v128_hi(v) vgetq_lane_u64(vreinterpretq_u64_u8(v), 1)
#define Moonbit_v128_load_storage(p) vld1q_u8((const uint8_t *)(p))
#define Moonbit_v128_store_storage(p, v) vst1q_u8((uint8_t *)(p), (v))
#elif defined(MOONBIT_V128_SSE2)
#define Moonbit_v128_make(lo, hi) _mm_set_epi64x((int64_t)(hi), (int64_t)(lo))
#define Moonbit_v128_lo(v) ((uint64_t)_mm_cvtsi128_si64(v))
#define Moonbit_v128_hi(v) ((uint64_t)_mm_cvtsi128_si64(_mm_srli_si128((v), 8)))
#define Moonbit_v128_load_storage(p) _mm_loadu_si128((const __m128i *)(p))
#define Moonbit_v128_store_storage(p, v) _mm_storeu_si128((__m128i *)(p), (v))
#else
#define Moonbit_v128_make(lo, hi) ((moonbit_v128_t){(lo), (hi)})
#define Moonbit_v128_lo(v) ((v).lo)
#define Moonbit_v128_hi(v) ((v).hi)
#define Moonbit_v128_load_storage(p) (*(p))
#define Moonbit_v128_store_storage(p, v) (*(p) = (v))
#endif

// detect whether compiler builtins exist for advanced bitwise operations
#ifdef __has_builtin

#if __has_builtin(__builtin_clz)
#define HAS_BUILTIN_CLZ
#endif

#if __has_builtin(__builtin_ctz)
#define HAS_BUILTIN_CTZ
#endif

#if __has_builtin(__builtin_popcount)
#define HAS_BUILTIN_POPCNT
#endif

#if __has_builtin(__builtin_sqrt)
#define HAS_BUILTIN_SQRT
#endif

#if __has_builtin(__builtin_sqrtf)
#define HAS_BUILTIN_SQRTF
#endif

#if __has_builtin(__builtin_fabs)
#define HAS_BUILTIN_FABS
#endif

#if __has_builtin(__builtin_fabsf)
#define HAS_BUILTIN_FABSF
#endif

#endif

// if there is no builtin operators, use software implementation
#ifdef HAS_BUILTIN_CLZ
static inline int32_t moonbit_clz32(int32_t x) {
  return x == 0 ? 32 : __builtin_clz(x);
}

static inline int32_t moonbit_clz64(int64_t x) {
  return x == 0 ? 64 : __builtin_clzll(x);
}

#undef HAS_BUILTIN_CLZ
#else
// table for [clz] value of 4bit integer.
static const uint8_t moonbit_clz4[] = {4, 3, 2, 2, 1, 1, 1, 1,
                                       0, 0, 0, 0, 0, 0, 0, 0};

int32_t moonbit_clz32(uint32_t x) {
  /* The ideas is to:

     1. narrow down the 4bit block where the most signficant "1" bit lies,
        using binary search
     2. find the number of leading zeros in that 4bit block via table lookup

     Different time/space tradeoff can be made here by enlarging the table
     and do less binary search.
     One benefit of the 4bit lookup table is that it can fit into a single cache
     line.
  */
  int32_t result = 0;
  if (x > 0xffff) {
    x >>= 16;
  } else {
    result += 16;
  }
  if (x > 0xff) {
    x >>= 8;
  } else {
    result += 8;
  }
  if (x > 0xf) {
    x >>= 4;
  } else {
    result += 4;
  }
  return result + moonbit_clz4[x];
}

int32_t moonbit_clz64(uint64_t x) {
  int32_t result = 0;
  if (x > 0xffffffff) {
    x >>= 32;
  } else {
    result += 32;
  }
  return result + moonbit_clz32((uint32_t)x);
}
#endif

#ifdef HAS_BUILTIN_CTZ
static inline int32_t moonbit_ctz32(int32_t x) {
  return x == 0 ? 32 : __builtin_ctz(x);
}

static inline int32_t moonbit_ctz64(int64_t x) {
  return x == 0 ? 64 : __builtin_ctzll(x);
}

#undef HAS_BUILTIN_CTZ
#else
int32_t moonbit_ctz32(int32_t x) {
  /* The algorithm comes from:

       Leiserson, Charles E. et al. “Using de Bruijn Sequences to Index a 1 in a
     Computer Word.” (1998).

     The ideas is:

     1. leave only the least significant "1" bit in the input,
        set all other bits to "0". This is achieved via [x & -x]
     2. now we have [x * n == n << ctz(x)], if [n] is a de bruijn sequence
        (every 5bit pattern occurn exactly once when you cycle through the bit
     string), we can find [ctz(x)] from the most significant 5 bits of [x * n]
 */
  static const uint32_t de_bruijn_32 = 0x077CB531;
  static const uint8_t index32[] = {0,  1,  28, 2,  29, 14, 24, 3,  30, 22, 20,
                                    15, 25, 17, 4,  8,  31, 27, 13, 23, 21, 19,
                                    16, 7,  26, 12, 18, 6,  11, 5,  10, 9};
  return (x == 0) * 32 + index32[(de_bruijn_32 * (x & -x)) >> 27];
}

int32_t moonbit_ctz64(int64_t x) {
  static const uint64_t de_bruijn_64 = 0x0218A392CD3D5DBF;
  static const uint8_t index64[] = {
      0,  1,  2,  7,  3,  13, 8,  19, 4,  25, 14, 28, 9,  34, 20, 40,
      5,  17, 26, 38, 15, 46, 29, 48, 10, 31, 35, 54, 21, 50, 41, 57,
      63, 6,  12, 18, 24, 27, 33, 39, 16, 37, 45, 47, 30, 53, 49, 56,
      62, 11, 23, 32, 36, 44, 52, 55, 61, 22, 43, 51, 60, 42, 59, 58};
  return (x == 0) * 64 + index64[(de_bruijn_64 * (x & -x)) >> 58];
}
#endif

#ifdef HAS_BUILTIN_POPCNT

#define moonbit_popcnt32 __builtin_popcount
#define moonbit_popcnt64 __builtin_popcountll
#undef HAS_BUILTIN_POPCNT

#else
int32_t moonbit_popcnt32(uint32_t x) {
  /* The classic SIMD Within A Register algorithm.
     ref: [https://nimrod.blog/posts/algorithms-behind-popcount/]
 */
  x = x - ((x >> 1) & 0x55555555);
  x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
  x = (x + (x >> 4)) & 0x0F0F0F0F;
  return (x * 0x01010101) >> 24;
}

int32_t moonbit_popcnt64(uint64_t x) {
  x = x - ((x >> 1) & 0x5555555555555555);
  x = (x & 0x3333333333333333) + ((x >> 2) & 0x3333333333333333);
  x = (x + (x >> 4)) & 0x0F0F0F0F0F0F0F0F;
  return (x * 0x0101010101010101) >> 56;
}
#endif

/* The following sqrt implementation comes from
   [musl](https://git.musl-libc.org/cgit/musl),
   with some helpers inlined to make it zero dependency.
 */
#ifdef MOONBIT_NATIVE_NO_SYS_HEADER
const uint16_t __rsqrt_tab[128] = {
    0xb451, 0xb2f0, 0xb196, 0xb044, 0xaef9, 0xadb6, 0xac79, 0xab43, 0xaa14,
    0xa8eb, 0xa7c8, 0xa6aa, 0xa592, 0xa480, 0xa373, 0xa26b, 0xa168, 0xa06a,
    0x9f70, 0x9e7b, 0x9d8a, 0x9c9d, 0x9bb5, 0x9ad1, 0x99f0, 0x9913, 0x983a,
    0x9765, 0x9693, 0x95c4, 0x94f8, 0x9430, 0x936b, 0x92a9, 0x91ea, 0x912e,
    0x9075, 0x8fbe, 0x8f0a, 0x8e59, 0x8daa, 0x8cfe, 0x8c54, 0x8bac, 0x8b07,
    0x8a64, 0x89c4, 0x8925, 0x8889, 0x87ee, 0x8756, 0x86c0, 0x862b, 0x8599,
    0x8508, 0x8479, 0x83ec, 0x8361, 0x82d8, 0x8250, 0x81c9, 0x8145, 0x80c2,
    0x8040, 0xff02, 0xfd0e, 0xfb25, 0xf947, 0xf773, 0xf5aa, 0xf3ea, 0xf234,
    0xf087, 0xeee3, 0xed47, 0xebb3, 0xea27, 0xe8a3, 0xe727, 0xe5b2, 0xe443,
    0xe2dc, 0xe17a, 0xe020, 0xdecb, 0xdd7d, 0xdc34, 0xdaf1, 0xd9b3, 0xd87b,
    0xd748, 0xd61a, 0xd4f1, 0xd3cd, 0xd2ad, 0xd192, 0xd07b, 0xcf69, 0xce5b,
    0xcd51, 0xcc4a, 0xcb48, 0xca4a, 0xc94f, 0xc858, 0xc764, 0xc674, 0xc587,
    0xc49d, 0xc3b7, 0xc2d4, 0xc1f4, 0xc116, 0xc03c, 0xbf65, 0xbe90, 0xbdbe,
    0xbcef, 0xbc23, 0xbb59, 0xba91, 0xb9cc, 0xb90a, 0xb84a, 0xb78c, 0xb6d0,
    0xb617, 0xb560,
};

/* returns a*b*2^-32 - e, with error 0 <= e < 1.  */
static inline uint32_t mul32(uint32_t a, uint32_t b) {
  return (uint64_t)a * b >> 32;
}
#endif

#ifdef MOONBIT_NATIVE_NO_SYS_HEADER
float sqrtf(float x) {
  uint32_t ix, m, m1, m0, even, ey;

  ix = *(uint32_t *)&x;
  if (ix - 0x00800000 >= 0x7f800000 - 0x00800000) {
    /* x < 0x1p-126 or inf or nan.  */
    if (ix * 2 == 0)
      return x;
    if (ix == 0x7f800000)
      return x;
    if (ix > 0x7f800000)
      return (x - x) / (x - x);
    /* x is subnormal, normalize it.  */
    x *= 0x1p23f;
    ix = *(uint32_t *)&x;
    ix -= 23 << 23;
  }

  /* x = 4^e m; with int e and m in [1, 4).  */
  even = ix & 0x00800000;
  m1 = (ix << 8) | 0x80000000;
  m0 = (ix << 7) & 0x7fffffff;
  m = even ? m0 : m1;

  /* 2^e is the exponent part of the return value.  */
  ey = ix >> 1;
  ey += 0x3f800000 >> 1;
  ey &= 0x7f800000;

  /* compute r ~ 1/sqrt(m), s ~ sqrt(m) with 2 goldschmidt iterations.  */
  static const uint32_t three = 0xc0000000;
  uint32_t r, s, d, u, i;
  i = (ix >> 17) % 128;
  r = (uint32_t)__rsqrt_tab[i] << 16;
  /* |r*sqrt(m) - 1| < 0x1p-8 */
  s = mul32(m, r);
  /* |s/sqrt(m) - 1| < 0x1p-8 */
  d = mul32(s, r);
  u = three - d;
  r = mul32(r, u) << 1;
  /* |r*sqrt(m) - 1| < 0x1.7bp-16 */
  s = mul32(s, u) << 1;
  /* |s/sqrt(m) - 1| < 0x1.7bp-16 */
  d = mul32(s, r);
  u = three - d;
  s = mul32(s, u);
  /* -0x1.03p-28 < s/sqrt(m) - 1 < 0x1.fp-31 */
  s = (s - 1) >> 6;
  /* s < sqrt(m) < s + 0x1.08p-23 */

  /* compute nearest rounded result.  */
  uint32_t d0, d1, d2;
  float y, t;
  d0 = (m << 16) - s * s;
  d1 = s - d0;
  d2 = d1 + s + 1;
  s += d1 >> 31;
  s &= 0x007fffff;
  s |= ey;
  y = *(float *)&s;
  /* handle rounding and inexact exception. */
  uint32_t tiny = d2 == 0 ? 0 : 0x01000000;
  tiny |= (d1 ^ d2) & 0x80000000;
  t = *(float *)&tiny;
  y = y + t;
  return y;
}
#endif

#ifdef MOONBIT_NATIVE_NO_SYS_HEADER
/* returns a*b*2^-64 - e, with error 0 <= e < 3.  */
static inline uint64_t mul64(uint64_t a, uint64_t b) {
  uint64_t ahi = a >> 32;
  uint64_t alo = a & 0xffffffff;
  uint64_t bhi = b >> 32;
  uint64_t blo = b & 0xffffffff;
  return ahi * bhi + (ahi * blo >> 32) + (alo * bhi >> 32);
}

double sqrt(double x) {
  uint64_t ix, top, m;

  /* special case handling.  */
  ix = *(uint64_t *)&x;
  top = ix >> 52;
  if (top - 0x001 >= 0x7ff - 0x001) {
    /* x < 0x1p-1022 or inf or nan.  */
    if (ix * 2 == 0)
      return x;
    if (ix == 0x7ff0000000000000)
      return x;
    if (ix > 0x7ff0000000000000)
      return (x - x) / (x - x);
    /* x is subnormal, normalize it.  */
    x *= 0x1p52;
    ix = *(uint64_t *)&x;
    top = ix >> 52;
    top -= 52;
  }

  /* argument reduction:
     x = 4^e m; with integer e, and m in [1, 4)
     m: fixed point representation [2.62]
     2^e is the exponent part of the result.  */
  int even = top & 1;
  m = (ix << 11) | 0x8000000000000000;
  if (even)
    m >>= 1;
  top = (top + 0x3ff) >> 1;

  /* approximate r ~ 1/sqrt(m) and s ~ sqrt(m) when m in [1,4)

     initial estimate:
     7bit table lookup (1bit exponent and 6bit significand).

     iterative approximation:
     using 2 goldschmidt iterations with 32bit int arithmetics
     and a final iteration with 64bit int arithmetics.

     details:

     the relative error (e = r0 sqrt(m)-1) of a linear estimate
     (r0 = a m + b) is |e| < 0.085955 ~ 0x1.6p-4 at best,
     a table lookup is faster and needs one less iteration
     6 bit lookup table (128b) gives |e| < 0x1.f9p-8
     7 bit lookup table (256b) gives |e| < 0x1.fdp-9
     for single and double prec 6bit is enough but for quad
     prec 7bit is needed (or modified iterations). to avoid
     one more iteration >=13bit table would be needed (16k).

     a newton-raphson iteration for r is
       w = r*r
       u = 3 - m*w
       r = r*u/2
     can use a goldschmidt iteration for s at the end or
       s = m*r

     first goldschmidt iteration is
       s = m*r
       u = 3 - s*r
       r = r*u/2
       s = s*u/2
     next goldschmidt iteration is
       u = 3 - s*r
       r = r*u/2
       s = s*u/2
     and at the end r is not computed only s.

     they use the same amount of operations and converge at the
     same quadratic rate, i.e. if
       r1 sqrt(m) - 1 = e, then
       r2 sqrt(m) - 1 = -3/2 e^2 - 1/2 e^3
     the advantage of goldschmidt is that the mul for s and r
     are independent (computed in parallel), however it is not
     "self synchronizing": it only uses the input m in the
     first iteration so rounding errors accumulate. at the end
     or when switching to larger precision arithmetics rounding
     errors dominate so the first iteration should be used.

     the fixed point representations are
       m: 2.30 r: 0.32, s: 2.30, d: 2.30, u: 2.30, three: 2.30
     and after switching to 64 bit
       m: 2.62 r: 0.64, s: 2.62, d: 2.62, u: 2.62, three: 2.62  */

  static const uint64_t three = 0xc0000000;
  uint64_t r, s, d, u, i;

  i = (ix >> 46) % 128;
  r = (uint32_t)__rsqrt_tab[i] << 16;
  /* |r sqrt(m) - 1| < 0x1.fdp-9 */
  s = mul32(m >> 32, r);
  /* |s/sqrt(m) - 1| < 0x1.fdp-9 */
  d = mul32(s, r);
  u = three - d;
  r = mul32(r, u) << 1;
  /* |r sqrt(m) - 1| < 0x1.7bp-16 */
  s = mul32(s, u) << 1;
  /* |s/sqrt(m) - 1| < 0x1.7bp-16 */
  d = mul32(s, r);
  u = three - d;
  r = mul32(r, u) << 1;
  /* |r sqrt(m) - 1| < 0x1.3704p-29 (measured worst-case) */
  r = r << 32;
  s = mul64(m, r);
  d = mul64(s, r);
  u = (three << 32) - d;
  s = mul64(s, u); /* repr: 3.61 */
  /* -0x1p-57 < s - sqrt(m) < 0x1.8001p-61 */
  s = (s - 2) >> 9; /* repr: 12.52 */
  /* -0x1.09p-52 < s - sqrt(m) < -0x1.fffcp-63 */

  /* s < sqrt(m) < s + 0x1.09p-52,
     compute nearest rounded result:
     the nearest result to 52 bits is either s or s+0x1p-52,
     we can decide by comparing (2^52 s + 0.5)^2 to 2^104 m.  */
  uint64_t d0, d1, d2;
  double y, t;
  d0 = (m << 42) - s * s;
  d1 = s - d0;
  d2 = d1 + s + 1;
  s += d1 >> 63;
  s &= 0x000fffffffffffff;
  s |= top << 52;
  y = *(double *)&s;
  return y;
}
#endif

#ifdef MOONBIT_NATIVE_NO_SYS_HEADER
double fabs(double x) {
  union {
    double f;
    uint64_t i;
  } u = {x};
  u.i &= 0x7fffffffffffffffULL;
  return u.f;
}
#endif

#ifdef MOONBIT_NATIVE_NO_SYS_HEADER
float fabsf(float x) {
  union {
    float f;
    uint32_t i;
  } u = {x};
  u.i &= 0x7fffffff;
  return u.f;
}
#endif

#ifdef _MSC_VER
/* MSVC treats syntactic division by zero as fatal error,
   even for float point numbers,
   so we have to use a constant variable to work around this */
static const int MOONBIT_ZERO = 0;
#else
#define MOONBIT_ZERO 0
#endif

#ifdef __cplusplus
}
#endif
struct _M0TPB8MutLocalGiE;

struct _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure;

struct _M0DTPC15error5Error58moonbitlang_2fcore_2fbuiltin_2eInspectError_2eInspectError;

struct _M0DTPC15error5Error83re_2dmbt_2fre_2eMoonBitTestDriverInternalJsError_2eMoonBitTestDriverInternalJsError;

struct _M0TWRPC15error5ErrorEs;

struct _M0TPB4Show;

struct _M0TWssbEu;

struct _M0TUsiE;

struct _M0TPB13StringBuilder;

struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399;

struct _M0TWWuEuWRPC15error5ErrorEuEOuQRPC15error5Error;

struct _M0DTPC16result6ResultGbRP28re_2dmbt2re33MoonBitTestDriverInternalSkipTestE3Err;

struct _M0DTPC16result6ResultGbRP28re_2dmbt2re33MoonBitTestDriverInternalSkipTestE2Ok;

struct _M0DTPC16result6ResultGOuRPC15error5ErrorE3Err;

struct _M0BTPB6Logger;

struct _M0BTPB4Show;

struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404;

struct _M0TWuEu;

struct _M0TPC16string10StringView;

struct _M0KTPB6LoggerTPB13StringBuilder;

struct _M0TPB6Logger;

struct _M0TPB5ArrayGUsiEE;

struct _M0TPB5ArrayGsE;

struct _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok;

struct _M0TWEu;

struct _M0DTPC15error5Error85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTest;

struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE;

struct _M0TURPB6LoggerRPC16string10StringViewE;

struct _M0DTPC15error5Error60moonbitlang_2fcore_2fbuiltin_2eSnapshotError_2eSnapshotError;

struct _M0TWRPC15error5ErrorEu;

struct _M0TPB8MutLocalGiE {
  int32_t $0;
  
};

struct _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure {
  moonbit_string_t $0;
  
};

struct _M0DTPC15error5Error58moonbitlang_2fcore_2fbuiltin_2eInspectError_2eInspectError {
  moonbit_string_t $0;
  
};

struct _M0DTPC15error5Error83re_2dmbt_2fre_2eMoonBitTestDriverInternalJsError_2eMoonBitTestDriverInternalJsError {
  moonbit_string_t $0;
  
};

struct _M0TWRPC15error5ErrorEs {
  moonbit_string_t(* code)(struct _M0TWRPC15error5ErrorEs*, void*);
  
};

struct _M0TPB4Show {
  struct _M0BTPB4Show* $0;
  void* $1;
  
};

struct _M0TWssbEu {
  int32_t(* code)(
    struct _M0TWssbEu*,
    moonbit_string_t,
    moonbit_string_t,
    int32_t
  );
  
};

struct _M0TUsiE {
  moonbit_string_t $0;
  int32_t $1;
  
};

struct _M0TPB13StringBuilder {
  uint16_t* $0;
  int32_t $1;
  
};

struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399 {
  int32_t(* code)(struct _M0TWEu*);
  int32_t $0;
  moonbit_string_t $1;
  
};

struct _M0TWWuEuWRPC15error5ErrorEuEOuQRPC15error5Error {
  struct moonbit_result_0(* code)(
    struct _M0TWWuEuWRPC15error5ErrorEuEOuQRPC15error5Error*,
    struct _M0TWuEu*,
    struct _M0TWRPC15error5ErrorEu*
  );
  
};

struct _M0DTPC16result6ResultGbRP28re_2dmbt2re33MoonBitTestDriverInternalSkipTestE3Err {
  void* $0;
  
};

struct _M0DTPC16result6ResultGbRP28re_2dmbt2re33MoonBitTestDriverInternalSkipTestE2Ok {
  int32_t $0;
  
};

struct _M0DTPC16result6ResultGOuRPC15error5ErrorE3Err {
  void* $0;
  
};

struct _M0BTPB6Logger {
  int32_t(* $method_0)(void*, moonbit_string_t);
  int32_t(* $method_1)(void*, moonbit_string_t, int32_t, int32_t);
  int32_t(* $method_2)(void*, struct _M0TPC16string10StringView);
  int32_t(* $method_3)(void*, int32_t);
  int32_t(* $method_4)(void*, struct _M0TPB4Show);
  int32_t(* $method_5)(void*, struct _M0TPB4Show);
  
};

struct _M0BTPB4Show {
  int32_t(* $method_0)(void*, struct _M0TPB6Logger);
  moonbit_string_t(* $method_1)(void*);
  
};

struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404 {
  int32_t(* code)(
    struct _M0TWssbEu*,
    moonbit_string_t,
    moonbit_string_t,
    int32_t
  );
  int32_t $0;
  moonbit_string_t $1;
  
};

struct _M0TWuEu {
  int32_t(* code)(struct _M0TWuEu*, int32_t);
  
};

struct _M0TPC16string10StringView {
  moonbit_string_t $0;
  int32_t $1;
  int32_t $2;
  
};

struct _M0KTPB6LoggerTPB13StringBuilder {
  struct _M0BTPB6Logger* $0;
  void* $1;
  
};

struct _M0TPB6Logger {
  struct _M0BTPB6Logger* $0;
  void* $1;
  
};

struct _M0TPB5ArrayGUsiEE {
  struct _M0TUsiE** $0;
  int32_t $1;
  
};

struct _M0TPB5ArrayGsE {
  moonbit_string_t* $0;
  int32_t $1;
  
};

struct _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok {
  int32_t $0;
  
};

struct _M0TWEu {
  int32_t(* code)(struct _M0TWEu*);
  
};

struct _M0DTPC15error5Error85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTest {
  moonbit_string_t $0;
  
};

struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE {
  struct _M0TWWuEuWRPC15error5ErrorEuEOuQRPC15error5Error** $0;
  int32_t $1;
  
};

struct _M0TURPB6LoggerRPC16string10StringViewE {
  struct _M0TPB6Logger $0;
  struct _M0TPC16string10StringView $1;
  
};

struct _M0DTPC15error5Error60moonbitlang_2fcore_2fbuiltin_2eSnapshotError_2eSnapshotError {
  moonbit_string_t $0;
  
};

struct _M0TWRPC15error5ErrorEu {
  int32_t(* code)(struct _M0TWRPC15error5ErrorEu*, void*);
  
};

struct moonbit_result_0 {
  int tag;
  union { int32_t ok; void* err;  } data;
  
};

int32_t _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver30is__being__cancelled_2edyncallGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE(
  struct _M0TWEu*
);

int32_t _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__execute(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE*,
  moonbit_string_t,
  int32_t
);

moonbit_string_t _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN17error__to__stringS411(
  struct _M0TWRPC15error5ErrorEs*,
  void*
);

int32_t _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN14handle__resultS404(
  struct _M0TWssbEu*,
  moonbit_string_t,
  moonbit_string_t,
  int32_t
);

int32_t _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN13handle__startS399(
  struct _M0TWEu*
);

struct _M0TPB5ArrayGUsiEE* _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__args(
  
);

struct _M0TPB5ArrayGsE* _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN51moonbit__test__driver__internal__split__mbt__stringS377(
  int32_t,
  moonbit_string_t,
  int32_t
);

struct _M0TPB5ArrayGsE* _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN57moonbit__test__driver__internal__get__cli__args__internalS370(
  int32_t
);

moonbit_string_t _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN61moonbit__test__driver__internal__utf8__bytes__to__mbt__stringS363(
  int32_t,
  moonbit_bytes_t
);

int32_t _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN45moonbit__test__driver__internal__parse__int__S356(
  int32_t,
  moonbit_string_t
);

#define _M0FP28re_2dmbt2re52moonbit__test__driver__internal__get__cli__args__ffi moonbit_get_cli_args

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re41MoonBit__Test__Driver__Internal__No__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE*,
  moonbit_string_t,
  int32_t,
  struct _M0TWEu*,
  struct _M0TWssbEu*,
  struct _M0TWRPC15error5ErrorEs*
);

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re43MoonBit__Test__Driver__Internal__With__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE*,
  moonbit_string_t,
  int32_t,
  struct _M0TWEu*,
  struct _M0TWssbEu*,
  struct _M0TWRPC15error5ErrorEs*
);

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re48MoonBit__Test__Driver__Internal__Async__No__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE*,
  moonbit_string_t,
  int32_t,
  struct _M0TWEu*,
  struct _M0TWssbEu*,
  struct _M0TWRPC15error5ErrorEs*
);

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re50MoonBit__Test__Driver__Internal__Async__With__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE*,
  moonbit_string_t,
  int32_t,
  struct _M0TWEu*,
  struct _M0TWssbEu*,
  struct _M0TWRPC15error5ErrorEs*
);

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re50MoonBit__Test__Driver__Internal__With__Bench__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE*,
  moonbit_string_t,
  int32_t,
  struct _M0TWEu*,
  struct _M0TWssbEu*,
  struct _M0TWRPC15error5ErrorEs*
);

int32_t _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver20is__being__cancelledGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE(
  
);

int32_t _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver17run__async__testsGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE*
);

moonbit_string_t _M0MPC15array5Array2atGsE(struct _M0TPB5ArrayGsE*, int32_t);

int32_t _M0FPB7printlnGsE(moonbit_string_t);

moonbit_string_t _M0IPC13int3IntPB4Show10to__string(int32_t);

int32_t _M0MPC15array5Array4pushGsE(
  struct _M0TPB5ArrayGsE*,
  moonbit_string_t
);

int32_t _M0MPC15array5Array4pushGUsiEE(
  struct _M0TPB5ArrayGUsiEE*,
  struct _M0TUsiE*
);

int32_t _M0MPC15array5Array7reallocGsE(struct _M0TPB5ArrayGsE*);

int32_t _M0MPC15array5Array7reallocGUsiEE(struct _M0TPB5ArrayGUsiEE*);

int32_t _M0MPC15array5Array14resize__bufferGsE(
  struct _M0TPB5ArrayGsE*,
  int32_t
);

int32_t _M0MPC15array5Array14resize__bufferGUsiEE(
  struct _M0TPB5ArrayGUsiEE*,
  int32_t
);

moonbit_string_t* _M0MPC15array5Array6bufferGsE(struct _M0TPB5ArrayGsE*);

struct _M0TUsiE** _M0MPC15array5Array6bufferGUsiEE(
  struct _M0TPB5ArrayGUsiEE*
);

struct _M0TPB5ArrayGsE* _M0MPC15array5Array11new_2einnerGsE(int32_t);

moonbit_string_t _M0IPC16string6StringPB4Show10to__string(moonbit_string_t);

int32_t _M0IPB13StringBuilderPB6Logger11write__view(
  struct _M0TPB13StringBuilder*,
  struct _M0TPC16string10StringView
);

moonbit_string_t _M0MPC16string6String17unsafe__substring(
  moonbit_string_t,
  int32_t,
  int32_t
);

int32_t _M0IPC14byte4BytePB7Default7default();

moonbit_string_t _M0MPC15bytes5Bytes29to__unchecked__string_2einner(
  moonbit_bytes_t,
  int32_t,
  int64_t
);

#define _M0FPB19unsafe__sub__string moonbit_unsafe_bytes_sub_string

int32_t _M0MPC15array10FixedArray18blit__from__string(
  moonbit_bytes_t,
  int32_t,
  moonbit_string_t,
  int32_t,
  int32_t
);

int32_t _M0MPC14uint4UInt8to__byte(uint32_t);

moonbit_string_t _M0MPC13int3Int18to__string_2einner(int32_t, int32_t);

int32_t _M0FPB14radix__count32(uint32_t, int32_t);

int32_t _M0FPB12hex__count32(uint32_t);

int32_t _M0FPB12dec__count32(uint32_t);

int32_t _M0FPB20int__to__string__dec(uint16_t*, uint32_t, int32_t, int32_t);

int32_t _M0FPB24int__to__string__generic(
  uint16_t*,
  uint32_t,
  int32_t,
  int32_t,
  int32_t
);

int32_t _M0FPB20int__to__string__hex(uint16_t*, uint32_t, int32_t, int32_t);

moonbit_string_t _M0IP016_24default__implPB4Show10to__stringGRPB7FailureE(
  void*
);

int32_t _M0IP016_24default__implPB4Show6outputGsE(
  moonbit_string_t,
  struct _M0TPB6Logger
);

int32_t _M0IP016_24default__implPB4Show6outputGiE(
  int32_t,
  struct _M0TPB6Logger
);

int32_t _M0MPC16string10StringView13start__offset(
  struct _M0TPC16string10StringView
);

moonbit_string_t _M0MPC16string10StringView4data(
  struct _M0TPC16string10StringView
);

int32_t _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(
  struct _M0TPB13StringBuilder*,
  moonbit_string_t,
  int32_t,
  int32_t
);

struct _M0TPC16string10StringView _M0MPC16string6String11sub_2einner(
  moonbit_string_t,
  int32_t,
  int64_t
);

int32_t _M0IP016_24default__implPB6Logger5writeGRPB13StringBuilderE(
  struct _M0TPB13StringBuilder*,
  struct _M0TPB4Show
);

int32_t _M0IP016_24default__implPB6Logger28write__string__interpolationGRPB13StringBuilderE(
  struct _M0TPB13StringBuilder*,
  struct _M0TPB4Show
);

int32_t _M0IPB13StringBuilderPB6Logger13write__string(
  struct _M0TPB13StringBuilder*,
  moonbit_string_t
);

int32_t _M0MPC15array10FixedArray26unsafe__blit__from__string(
  uint16_t*,
  int32_t,
  moonbit_string_t,
  int32_t,
  int32_t
);

moonbit_string_t _M0MPC16string6String14escape_2einner(
  moonbit_string_t,
  int32_t
);

int32_t _M0MPC16string10StringView18escape__to_2einner(
  struct _M0TPC16string10StringView,
  struct _M0TPB6Logger,
  int32_t
);

int32_t _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(
  struct _M0TURPB6LoggerRPC16string10StringViewE*,
  int32_t,
  int32_t
);

struct _M0TPC16string10StringView _M0MPC16string10StringView11sub_2einner(
  struct _M0TPC16string10StringView,
  int32_t,
  int64_t
);

moonbit_string_t _M0MPC14byte4Byte7to__hex(int32_t);

int32_t _M0MPC14byte4Byte7to__hexN14to__hex__digitS4257(int32_t);

int32_t _M0IPC14byte4BytePB3Sub3sub(int32_t, int32_t);

int32_t _M0IPC14byte4BytePB3Mod3mod(int32_t, int32_t);

int32_t _M0IPC14byte4BytePB3Div3div(int32_t, int32_t);

int32_t _M0IPC14byte4BytePB3Add3add(int32_t, int32_t);

int32_t _M0MPC16uint166UInt1616unsafe__to__char(int32_t);

int32_t _M0MPC16uint166UInt1623is__trailing__surrogate(int32_t);

int32_t _M0IPB13StringBuilderPB6Logger11write__char(
  struct _M0TPB13StringBuilder*,
  int32_t
);

int32_t _M0MPB13StringBuilder19grow__if__necessary(
  struct _M0TPB13StringBuilder*,
  int32_t
);

int32_t _M0MPC14uint4UInt10to__uint16(uint32_t);

uint32_t _M0MPC14char4Char8to__uint(int32_t);

moonbit_string_t _M0MPB13StringBuilder10to__string(
  struct _M0TPB13StringBuilder*
);

int32_t _M0IPC16uint166UInt16PB7Default7default();

uint16_t* _M0MPC15array10FixedArray23make__and__blit_2einnerGkE(
  uint16_t*,
  int32_t,
  int32_t,
  int32_t,
  int32_t,
  int32_t
);

uint16_t* _M0MPC15array10FixedArray23unsafe__make__and__blitGkE(
  uint16_t*,
  int32_t,
  int32_t,
  int32_t,
  int32_t,
  int32_t
);

struct _M0TPB13StringBuilder* _M0MPB13StringBuilder21StringBuilder_2einner(
  int32_t
);

int32_t _M0MPC14byte4Byte8to__char(int32_t);

moonbit_string_t* _M0MPB18UninitializedArray23make__and__blit_2einnerGsE(
  moonbit_string_t*,
  int32_t,
  int32_t,
  int32_t,
  int32_t
);

struct _M0TUsiE** _M0MPB18UninitializedArray23make__and__blit_2einnerGUsiEE(
  struct _M0TUsiE**,
  int32_t,
  int32_t,
  int32_t,
  int32_t
);

int32_t _M0MPB13StringBuilder13write__objectGsE(
  struct _M0TPB13StringBuilder*,
  moonbit_string_t
);

int32_t _M0MPB13StringBuilder13write__objectGiE(
  struct _M0TPB13StringBuilder*,
  int32_t
);

moonbit_string_t* _M0MPB18UninitializedArray23unsafe__make__and__blitGsE(
  moonbit_string_t*,
  int32_t,
  int32_t,
  int32_t,
  int32_t
);

struct _M0TUsiE** _M0MPB18UninitializedArray23unsafe__make__and__blitGUsiEE(
  struct _M0TUsiE**,
  int32_t,
  int32_t,
  int32_t,
  int32_t
);

int32_t _M0MPB18UninitializedArray12unsafe__blitGsE(
  moonbit_string_t*,
  int32_t,
  moonbit_string_t*,
  int32_t,
  int32_t
);

int32_t _M0MPB18UninitializedArray12unsafe__blitGUsiEE(
  struct _M0TUsiE**,
  int32_t,
  struct _M0TUsiE**,
  int32_t,
  int32_t
);

int32_t _M0MPC15array10FixedArray12unsafe__blitGkE(
  uint16_t*,
  int32_t,
  uint16_t*,
  int32_t,
  int32_t
);

int32_t _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGsEE(
  moonbit_string_t*,
  int32_t,
  moonbit_string_t*,
  int32_t,
  int32_t
);

int32_t _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGUsiEEE(
  struct _M0TUsiE**,
  int32_t,
  struct _M0TUsiE**,
  int32_t,
  int32_t
);

int32_t _M0MPB18UninitializedArray6lengthGsE(moonbit_string_t*);

int32_t _M0MPB18UninitializedArray6lengthGUsiEE(struct _M0TUsiE**);

int32_t _M0IPB7FailurePB4Show6output(void*, struct _M0TPB6Logger);

int32_t _M0MPB6Logger13write__objectGsE(
  struct _M0TPB6Logger,
  moonbit_string_t
);

int32_t _M0FPC15abort5abortGuE(moonbit_string_t);

uint16_t* _M0FPC15abort5abortGAkE(moonbit_string_t);

moonbit_string_t* _M0FPC15abort5abortGRPB18UninitializedArrayGsEE(
  moonbit_string_t
);

struct _M0TUsiE** _M0FPC15abort5abortGRPB18UninitializedArrayGUsiEEE(
  moonbit_string_t
);

moonbit_string_t _M0FP15Error10to__string(void*);

int32_t _M0IP016_24default__implPB6Logger61write_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE(
  void*,
  struct _M0TPB4Show
);

int32_t _M0IP016_24default__implPB6Logger84write__string__interpolation_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE(
  void*,
  struct _M0TPB4Show
);

int32_t _M0IPB13StringBuilderPB6Logger67write__char_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger(
  void*,
  int32_t
);

int32_t _M0IPB13StringBuilderPB6Logger67write__view_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger(
  void*,
  struct _M0TPC16string10StringView
);

int32_t _M0IP016_24default__implPB6Logger72write__substring_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE(
  void*,
  moonbit_string_t,
  int32_t,
  int32_t
);

int32_t _M0IPB13StringBuilderPB6Logger69write__string_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger(
  void*,
  moonbit_string_t
);

struct { int32_t rc; uint32_t meta; uint16_t const data[35]; 
} const moonbit_string_literal_2 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 34, 45, 45, 
    45, 45, 45, 32, 66, 69, 71, 73, 78, 32, 77, 79, 79, 78, 32, 84, 69, 
    83, 84, 32, 82, 69, 83, 85, 76, 84, 32, 45, 45, 45, 45, 45, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[13]; 
} const moonbit_string_literal_1 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 12, 115, 107, 
    105, 112, 112, 101, 100, 32, 116, 101, 115, 116, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[1]; 
} const moonbit_string_literal_0 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 0, 0};

struct { int32_t rc; uint32_t meta; uint16_t const data[3]; 
} const moonbit_string_literal_15 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 2, 92, 116, 0};

struct { int32_t rc; uint32_t meta; uint16_t const data[3]; 
} const moonbit_string_literal_13 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 2, 92, 114, 0};

struct { int32_t rc; uint32_t meta; uint16_t const data[16]; 
} const moonbit_string_literal_20 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 15, 44, 32, 
    100, 115, 116, 95, 111, 102, 102, 115, 101, 116, 32, 61, 32, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[19]; 
} const moonbit_string_literal_17 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 18, 105, 110, 
    118, 97, 108, 105, 100, 32, 99, 111, 100, 101, 32, 112, 111, 105, 
    110, 116, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[12]; 
} const moonbit_string_literal_5 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 11, 44, 34, 
    109, 101, 115, 115, 97, 103, 101, 34, 58, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[53]; 
} const moonbit_string_literal_27 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 52, 109, 111, 
    111, 110, 98, 105, 116, 108, 97, 110, 103, 47, 99, 111, 114, 101, 
    47, 98, 117, 105, 108, 116, 105, 110, 46, 83, 110, 97, 112, 115, 
    104, 111, 116, 69, 114, 114, 111, 114, 46, 83, 110, 97, 112, 115, 
    104, 111, 116, 69, 114, 114, 111, 114, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[3]; 
} const moonbit_string_literal_12 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 2, 92, 110, 0};

struct { int32_t rc; uint32_t meta; uint16_t const data[31]; 
} const moonbit_string_literal_9 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 30, 114, 97, 
    100, 105, 120, 32, 109, 117, 115, 116, 32, 98, 101, 32, 98, 101, 
    116, 119, 101, 101, 110, 32, 50, 32, 97, 110, 100, 32, 51, 54, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[25]; 
} const moonbit_string_literal_3 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 24, 123, 34, 
    116, 121, 112, 101, 34, 58, 34, 114, 101, 115, 117, 108, 116, 34, 
    44, 34, 102, 105, 108, 101, 34, 58, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[2]; 
} const moonbit_string_literal_10 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 1, 48, 0};

struct { int32_t rc; uint32_t meta; uint16_t const data[76]; 
} const moonbit_string_literal_26 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 75, 114, 101, 
    45, 109, 98, 116, 47, 114, 101, 46, 77, 111, 111, 110, 66, 105, 116, 
    84, 101, 115, 116, 68, 114, 105, 118, 101, 114, 73, 110, 116, 101, 
    114, 110, 97, 108, 74, 115, 69, 114, 114, 111, 114, 46, 77, 111, 
    111, 110, 66, 105, 116, 84, 101, 115, 116, 68, 114, 105, 118, 101, 
    114, 73, 110, 116, 101, 114, 110, 97, 108, 74, 115, 69, 114, 114, 
    111, 114, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[9]; 
} const moonbit_string_literal_21 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 8, 44, 32, 
    108, 101, 110, 32, 61, 32, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[37]; 
} const moonbit_string_literal_18 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 36, 98, 111, 
    117, 110, 100, 115, 32, 99, 104, 101, 99, 107, 32, 102, 97, 105, 
    108, 101, 100, 58, 32, 97, 108, 108, 111, 99, 97, 116, 101, 95, 108, 
    101, 110, 32, 61, 32, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[4]; 
} const moonbit_string_literal_16 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 3, 92, 117, 123, 0};

struct { int32_t rc; uint32_t meta; uint16_t const data[2]; 
} const moonbit_string_literal_24 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 1, 41, 0};

struct { int32_t rc; uint32_t meta; uint16_t const data[37]; 
} const moonbit_string_literal_11 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 36, 48, 49, 
    50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102, 103, 104, 
    105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 
    118, 119, 120, 121, 122, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[3]; 
} const moonbit_string_literal_14 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 2, 92, 98, 0};

struct { int32_t rc; uint32_t meta; uint16_t const data[51]; 
} const moonbit_string_literal_25 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 50, 109, 111, 
    111, 110, 98, 105, 116, 108, 97, 110, 103, 47, 99, 111, 114, 101, 
    47, 98, 117, 105, 108, 116, 105, 110, 46, 73, 110, 115, 112, 101, 
    99, 116, 69, 114, 114, 111, 114, 46, 73, 110, 115, 112, 101, 99, 
    116, 69, 114, 114, 111, 114, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[16]; 
} const moonbit_string_literal_22 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 15, 44, 32, 
    115, 114, 99, 46, 108, 101, 110, 103, 116, 104, 32, 61, 32, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[33]; 
} const moonbit_string_literal_7 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 32, 45, 45, 
    45, 45, 45, 32, 69, 78, 68, 32, 77, 79, 79, 78, 32, 84, 69, 83, 84, 
    32, 82, 69, 83, 85, 76, 84, 32, 45, 45, 45, 45, 45, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[16]; 
} const moonbit_string_literal_19 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 15, 44, 32, 
    115, 114, 99, 95, 111, 102, 102, 115, 101, 116, 32, 61, 32, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[24]; 
} const moonbit_string_literal_8 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 23, 123, 34, 
    116, 121, 112, 101, 34, 58, 34, 115, 116, 97, 114, 116, 34, 44, 34, 
    102, 105, 108, 101, 34, 58, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[10]; 
} const moonbit_string_literal_4 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 9, 44, 34, 
    105, 110, 100, 101, 120, 34, 58, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[78]; 
} const moonbit_string_literal_28 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 77, 114, 101, 
    45, 109, 98, 116, 47, 114, 101, 46, 77, 111, 111, 110, 66, 105, 116, 
    84, 101, 115, 116, 68, 114, 105, 118, 101, 114, 73, 110, 116, 101, 
    114, 110, 97, 108, 83, 107, 105, 112, 84, 101, 115, 116, 46, 77, 
    111, 111, 110, 66, 105, 116, 84, 101, 115, 116, 68, 114, 105, 118, 
    101, 114, 73, 110, 116, 101, 114, 110, 97, 108, 83, 107, 105, 112, 
    84, 101, 115, 116, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[9]; 
} const moonbit_string_literal_23 =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 8, 70, 97, 
    105, 108, 117, 114, 101, 40, 0
  };

struct { int32_t rc; uint32_t meta; uint16_t const data[2]; 
} const moonbit_string_literal_6 =
  { Moonbit_make_static_rc(moonbit_BLOCK_KIND_VAL_ARRAY), 1, 125, 0};

struct { int32_t rc; uint32_t meta; struct _M0TWRPC15error5ErrorEs data; 
} const _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN17error__to__stringS411$closure =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_REGULAR),
    Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_SCALAR, 0, 0),
    _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN17error__to__stringS411
  };

struct { int32_t rc; uint32_t meta; struct _M0TWEu data; 
} const _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver30is__being__cancelled_2edyncallGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE$closure =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_REGULAR),
    Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_SCALAR, 0, 0),
    _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver30is__being__cancelled_2edyncallGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE
  };

uint32_t const moonbit_layout_table_data[36] =
  {
    sizeof(struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399)
    / 4, 1,
    offsetof(struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399, $1)
    / 4
    * 2,
    sizeof(struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404)
    / 4, 1,
    offsetof(struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404, $1)
    / 4
    * 2,
    sizeof(struct _M0DTPC15error5Error85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTest)
    / 4, 1,
    offsetof(struct _M0DTPC15error5Error85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTest, $0)
    / 4
    * 2, sizeof(struct _M0TPB5ArrayGUsiEE) / 4, 1,
    offsetof(struct _M0TPB5ArrayGUsiEE, $0) / 4 * 2,
    sizeof(struct _M0TUsiE) / 4, 1, offsetof(struct _M0TUsiE, $0) / 4 * 2,
    sizeof(struct _M0TPB5ArrayGsE) / 4, 1,
    offsetof(struct _M0TPB5ArrayGsE, $0) / 4 * 2,
    sizeof(struct _M0TPB6Logger) / 4, 2,
    offsetof(struct _M0TPB6Logger, $0) / 4 * 2,
    offsetof(struct _M0TPB6Logger, $1) / 4 * 2,
    sizeof(struct _M0TPC16string10StringView) / 4, 1,
    offsetof(struct _M0TPC16string10StringView, $0) / 4 * 2,
    sizeof(struct _M0TURPB6LoggerRPC16string10StringViewE) / 4, 3,
    (offsetof(struct _M0TURPB6LoggerRPC16string10StringViewE, $0)
     + offsetof(struct _M0TPB6Logger, $0))
    / 4
    * 2,
    (offsetof(struct _M0TURPB6LoggerRPC16string10StringViewE, $0)
     + offsetof(struct _M0TPB6Logger, $1))
    / 4
    * 2,
    (offsetof(struct _M0TURPB6LoggerRPC16string10StringViewE, $1)
     + offsetof(struct _M0TPC16string10StringView, $0))
    / 4
    * 2, sizeof(struct _M0TPB13StringBuilder) / 4, 1,
    offsetof(struct _M0TPB13StringBuilder, $0) / 4 * 2,
    sizeof(struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE) / 4, 1,
    offsetof(struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE, $0) / 4 * 2
  };

struct _M0TWEu* _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver26is__being__cancelled_2ecloGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE =
  (struct _M0TWEu*)&_M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver30is__being__cancelled_2edyncallGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE$closure.data;

struct { int32_t rc; uint32_t meta; struct _M0BTPB6Logger data; 
} _M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id$object =
  {
    Moonbit_make_static_rc(moonbit_BLOCK_KIND_REGULAR),
    Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_SCALAR, 0, 0),
    {.$method_0 = _M0IPB13StringBuilderPB6Logger69write__string_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger,
       .$method_1 = _M0IP016_24default__implPB6Logger72write__substring_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE,
       .$method_2 = _M0IPB13StringBuilderPB6Logger67write__view_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger,
       .$method_3 = _M0IPB13StringBuilderPB6Logger67write__char_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger,
       .$method_4 = _M0IP016_24default__implPB6Logger84write__string__interpolation_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE,
       .$method_5 = _M0IP016_24default__implPB6Logger61write_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE}
  };

struct _M0BTPB6Logger* _M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id =
  &_M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id$object.data;

int32_t _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver30is__being__cancelled_2edyncallGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE(
  struct _M0TWEu* _M0L6_2aenvS894
) {
  return _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver20is__being__cancelledGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE();
}

int32_t _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__execute(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE* _M0L12async__testsS432,
  moonbit_string_t _M0L8filenameS401,
  int32_t _M0L5indexS403
) {
  struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399* _closure_940;
  struct _M0TWEu* _M0L13handle__startS399;
  struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404* _closure_941;
  struct _M0TWssbEu* _M0L14handle__resultS404;
  struct _M0TWRPC15error5ErrorEs* _M0L17error__to__stringS411;
  void* _M0L11_2atry__errS426;
  struct moonbit_result_0 _tmp_943;
  int32_t _handle__error__result_944;
  int32_t _M0L6_2atmpS882;
  void* _M0L3errS427;
  moonbit_string_t _M0L4nameS429;
  struct _M0DTPC15error5Error85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTest* _M0L36_2aMoonBitTestDriverInternalSkipTestS430;
  moonbit_string_t _M0L8_2afieldS895;
  int32_t _M0L6_2acntS938;
  moonbit_string_t _M0L7_2anameS431;
  #line 553 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  moonbit_incref(_M0L8filenameS401);
  _closure_940
  = (struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399*)moonbit_malloc(sizeof(struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399));
  Moonbit_object_header(_closure_940)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 0, 0);
  _closure_940->code
  = &_M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN13handle__startS399;
  _closure_940->$0 = _M0L5indexS403;
  _closure_940->$1 = _M0L8filenameS401;
  _M0L13handle__startS399 = (struct _M0TWEu*)_closure_940;
  moonbit_incref(_M0L8filenameS401);
  _closure_941
  = (struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404*)moonbit_malloc(sizeof(struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404));
  Moonbit_object_header(_closure_941)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 3, 0);
  _closure_941->code
  = &_M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN14handle__resultS404;
  _closure_941->$0 = _M0L5indexS403;
  _closure_941->$1 = _M0L8filenameS401;
  _M0L14handle__resultS404 = (struct _M0TWssbEu*)_closure_941;
  _M0L17error__to__stringS411
  = (struct _M0TWRPC15error5ErrorEs*)&_M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN17error__to__stringS411$closure.data;
  #line 595 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _tmp_943
  = _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re41MoonBit__Test__Driver__Internal__No__ArgsE(_M0L12async__testsS432, _M0L8filenameS401, _M0L5indexS403, _M0L13handle__startS399, _M0L14handle__resultS404, _M0L17error__to__stringS411);
  if (_tmp_943.tag) {
    int32_t const _M0L5_2aokS891 = _tmp_943.data.ok;
    _handle__error__result_944 = _M0L5_2aokS891;
  } else {
    void* const _M0L6_2aerrS892 = _tmp_943.data.err;
    moonbit_decref(_M0L17error__to__stringS411);
    moonbit_decref(_M0L13handle__startS399);
    _M0L11_2atry__errS426 = _M0L6_2aerrS892;
    goto join_425;
  }
  if (_handle__error__result_944) {
    moonbit_decref(_M0L17error__to__stringS411);
    moonbit_decref(_M0L13handle__startS399);
    _M0L6_2atmpS882 = 1;
  } else {
    struct moonbit_result_0 _tmp_945;
    int32_t _handle__error__result_946;
    #line 598 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
    _tmp_945
    = _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re43MoonBit__Test__Driver__Internal__With__ArgsE(_M0L12async__testsS432, _M0L8filenameS401, _M0L5indexS403, _M0L13handle__startS399, _M0L14handle__resultS404, _M0L17error__to__stringS411);
    if (_tmp_945.tag) {
      int32_t const _M0L5_2aokS889 = _tmp_945.data.ok;
      _handle__error__result_946 = _M0L5_2aokS889;
    } else {
      void* const _M0L6_2aerrS890 = _tmp_945.data.err;
      moonbit_decref(_M0L17error__to__stringS411);
      moonbit_decref(_M0L13handle__startS399);
      _M0L11_2atry__errS426 = _M0L6_2aerrS890;
      goto join_425;
    }
    if (_handle__error__result_946) {
      moonbit_decref(_M0L17error__to__stringS411);
      moonbit_decref(_M0L13handle__startS399);
      _M0L6_2atmpS882 = 1;
    } else {
      struct moonbit_result_0 _tmp_947;
      int32_t _handle__error__result_948;
      #line 601 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _tmp_947
      = _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re48MoonBit__Test__Driver__Internal__Async__No__ArgsE(_M0L12async__testsS432, _M0L8filenameS401, _M0L5indexS403, _M0L13handle__startS399, _M0L14handle__resultS404, _M0L17error__to__stringS411);
      if (_tmp_947.tag) {
        int32_t const _M0L5_2aokS887 = _tmp_947.data.ok;
        _handle__error__result_948 = _M0L5_2aokS887;
      } else {
        void* const _M0L6_2aerrS888 = _tmp_947.data.err;
        moonbit_decref(_M0L17error__to__stringS411);
        moonbit_decref(_M0L13handle__startS399);
        _M0L11_2atry__errS426 = _M0L6_2aerrS888;
        goto join_425;
      }
      if (_handle__error__result_948) {
        moonbit_decref(_M0L17error__to__stringS411);
        moonbit_decref(_M0L13handle__startS399);
        _M0L6_2atmpS882 = 1;
      } else {
        struct moonbit_result_0 _tmp_949;
        int32_t _handle__error__result_950;
        #line 604 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
        _tmp_949
        = _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re50MoonBit__Test__Driver__Internal__Async__With__ArgsE(_M0L12async__testsS432, _M0L8filenameS401, _M0L5indexS403, _M0L13handle__startS399, _M0L14handle__resultS404, _M0L17error__to__stringS411);
        if (_tmp_949.tag) {
          int32_t const _M0L5_2aokS885 = _tmp_949.data.ok;
          _handle__error__result_950 = _M0L5_2aokS885;
        } else {
          void* const _M0L6_2aerrS886 = _tmp_949.data.err;
          moonbit_decref(_M0L17error__to__stringS411);
          moonbit_decref(_M0L13handle__startS399);
          _M0L11_2atry__errS426 = _M0L6_2aerrS886;
          goto join_425;
        }
        if (_handle__error__result_950) {
          moonbit_decref(_M0L17error__to__stringS411);
          moonbit_decref(_M0L13handle__startS399);
          _M0L6_2atmpS882 = 1;
        } else {
          struct moonbit_result_0 _tmp_951;
          #line 607 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
          _tmp_951
          = _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re50MoonBit__Test__Driver__Internal__With__Bench__ArgsE(_M0L12async__testsS432, _M0L8filenameS401, _M0L5indexS403, _M0L13handle__startS399, _M0L14handle__resultS404, _M0L17error__to__stringS411);
          moonbit_decref(_M0L13handle__startS399);
          moonbit_decref(_M0L17error__to__stringS411);
          if (_tmp_951.tag) {
            int32_t const _M0L5_2aokS883 = _tmp_951.data.ok;
            _M0L6_2atmpS882 = _M0L5_2aokS883;
          } else {
            void* const _M0L6_2aerrS884 = _tmp_951.data.err;
            _M0L11_2atry__errS426 = _M0L6_2aerrS884;
            goto join_425;
          }
        }
      }
    }
  }
  if (!_M0L6_2atmpS882) {
    void* _M0L85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTestS893 =
      (void*)moonbit_malloc(sizeof(struct _M0DTPC15error5Error85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTest));
    Moonbit_object_header(_M0L85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTestS893)->meta
    = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 6, 1);
    ((struct _M0DTPC15error5Error85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTest*)_M0L85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTestS893)->$0
    = (moonbit_string_t)moonbit_string_literal_0.data;
    _M0L11_2atry__errS426
    = _M0L85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTestS893;
    goto join_425;
  } else {
    moonbit_decref(_M0L14handle__resultS404);
  }
  goto joinlet_942;
  join_425:;
  _M0L3errS427 = _M0L11_2atry__errS426;
  _M0L36_2aMoonBitTestDriverInternalSkipTestS430
  = (struct _M0DTPC15error5Error85re_2dmbt_2fre_2eMoonBitTestDriverInternalSkipTest_2eMoonBitTestDriverInternalSkipTest*)_M0L3errS427;
  _M0L8_2afieldS895 = _M0L36_2aMoonBitTestDriverInternalSkipTestS430->$0;
  _M0L6_2acntS938
  = Moonbit_rc_count(Moonbit_object_header(_M0L36_2aMoonBitTestDriverInternalSkipTestS430));
  if (_M0L6_2acntS938 > 1) {
    int32_t _M0L11_2anew__cntS939 = _M0L6_2acntS938 - 1;
    Moonbit_set_rc_count(Moonbit_object_header(_M0L36_2aMoonBitTestDriverInternalSkipTestS430), _M0L11_2anew__cntS939);
    moonbit_incref(_M0L8_2afieldS895);
  } else if (_M0L6_2acntS938 == 1) {
    #line 614 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
    moonbit_free(_M0L36_2aMoonBitTestDriverInternalSkipTestS430);
  }
  _M0L7_2anameS431 = _M0L8_2afieldS895;
  _M0L4nameS429 = _M0L7_2anameS431;
  goto join_428;
  goto joinlet_952;
  join_428:;
  #line 615 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN14handle__resultS404(_M0L14handle__resultS404, _M0L4nameS429, (moonbit_string_t)moonbit_string_literal_1.data, 1);
  moonbit_decref(_M0L14handle__resultS404);
  moonbit_decref(_M0L4nameS429);
  joinlet_952:;
  joinlet_942:;
  return 0;
}

moonbit_string_t _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN17error__to__stringS411(
  struct _M0TWRPC15error5ErrorEs* _M0L6_2aenvS881,
  void* _M0L3errS412
) {
  void* _M0L1eS414;
  moonbit_string_t _M0L1eS416;
  moonbit_string_t _result_955;
  #line 584 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  switch (Moonbit_object_tag(_M0L3errS412)) {
    case 0: {
      struct _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure* _M0L10_2aFailureS417 =
        (struct _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure*)_M0L3errS412;
      moonbit_string_t _M0L4_2aeS418 = _M0L10_2aFailureS417->$0;
      moonbit_incref(_M0L4_2aeS418);
      _M0L1eS416 = _M0L4_2aeS418;
      goto join_415;
      break;
    }
    
    case 2: {
      struct _M0DTPC15error5Error58moonbitlang_2fcore_2fbuiltin_2eInspectError_2eInspectError* _M0L15_2aInspectErrorS419 =
        (struct _M0DTPC15error5Error58moonbitlang_2fcore_2fbuiltin_2eInspectError_2eInspectError*)_M0L3errS412;
      moonbit_string_t _M0L4_2aeS420 = _M0L15_2aInspectErrorS419->$0;
      moonbit_incref(_M0L4_2aeS420);
      _M0L1eS416 = _M0L4_2aeS420;
      goto join_415;
      break;
    }
    
    case 3: {
      struct _M0DTPC15error5Error60moonbitlang_2fcore_2fbuiltin_2eSnapshotError_2eSnapshotError* _M0L16_2aSnapshotErrorS421 =
        (struct _M0DTPC15error5Error60moonbitlang_2fcore_2fbuiltin_2eSnapshotError_2eSnapshotError*)_M0L3errS412;
      moonbit_string_t _M0L4_2aeS422 = _M0L16_2aSnapshotErrorS421->$0;
      moonbit_incref(_M0L4_2aeS422);
      _M0L1eS416 = _M0L4_2aeS422;
      goto join_415;
      break;
    }
    
    case 4: {
      struct _M0DTPC15error5Error83re_2dmbt_2fre_2eMoonBitTestDriverInternalJsError_2eMoonBitTestDriverInternalJsError* _M0L35_2aMoonBitTestDriverInternalJsErrorS423 =
        (struct _M0DTPC15error5Error83re_2dmbt_2fre_2eMoonBitTestDriverInternalJsError_2eMoonBitTestDriverInternalJsError*)_M0L3errS412;
      moonbit_string_t _M0L4_2aeS424 =
        _M0L35_2aMoonBitTestDriverInternalJsErrorS423->$0;
      moonbit_incref(_M0L4_2aeS424);
      _M0L1eS416 = _M0L4_2aeS424;
      goto join_415;
      break;
    }
    default: {
      moonbit_incref(_M0L3errS412);
      _M0L1eS414 = _M0L3errS412;
      goto join_413;
      break;
    }
  }
  join_415:;
  return _M0L1eS416;
  join_413:;
  #line 590 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _result_955 = _M0FP15Error10to__string(_M0L1eS414);
  moonbit_decref(_M0L1eS414);
  return _result_955;
}

int32_t _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN14handle__resultS404(
  struct _M0TWssbEu* _M0L6_2aenvS878,
  moonbit_string_t _M0L10__testnameS405,
  moonbit_string_t _M0L7messageS406,
  int32_t _M0L7skippedS407
) {
  struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404* _M0L14_2acasted__envS879;
  moonbit_string_t _M0L8filenameS401;
  int32_t _M0L5indexS403;
  int32_t _if__result_956;
  moonbit_string_t _M0L10file__nameS408;
  moonbit_string_t _M0L7messageS409;
  struct _M0TPB13StringBuilder* _M0L18_2astring__builderS410;
  moonbit_string_t _M0L6_2atmpS880;
  #line 569 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L14_2acasted__envS879
  = (struct _M0R86_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__result_7c404*)_M0L6_2aenvS878;
  _M0L8filenameS401 = _M0L14_2acasted__envS879->$1;
  _M0L5indexS403 = _M0L14_2acasted__envS879->$0;
  if (!_M0L7skippedS407) {
    _if__result_956 = 1;
  } else {
    _if__result_956 = 0;
  }
  if (_if__result_956) {
    
  }
  #line 575 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L10file__nameS408
  = _M0MPC16string6String14escape_2einner(_M0L8filenameS401, 1);
  #line 576 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L7messageS409
  = _M0MPC16string6String14escape_2einner(_M0L7messageS406, 1);
  #line 577 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0FPB7printlnGsE((moonbit_string_t)moonbit_string_literal_2.data);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L18_2astring__builderS410
  = _M0MPB13StringBuilder21StringBuilder_2einner(45);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS410, (moonbit_string_t)moonbit_string_literal_3.data);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0MPB13StringBuilder13write__objectGsE(_M0L18_2astring__builderS410, _M0L10file__nameS408);
  moonbit_decref(_M0L10file__nameS408);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS410, (moonbit_string_t)moonbit_string_literal_4.data);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS410, _M0L5indexS403);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS410, (moonbit_string_t)moonbit_string_literal_5.data);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0MPB13StringBuilder13write__objectGsE(_M0L18_2astring__builderS410, _M0L7messageS409);
  moonbit_decref(_M0L7messageS409);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS410, (moonbit_string_t)moonbit_string_literal_6.data);
  #line 579 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L6_2atmpS880
  = _M0MPB13StringBuilder10to__string(_M0L18_2astring__builderS410);
  moonbit_decref(_M0L18_2astring__builderS410);
  #line 578 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0FPB7printlnGsE(_M0L6_2atmpS880);
  moonbit_decref(_M0L6_2atmpS880);
  #line 581 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0FPB7printlnGsE((moonbit_string_t)moonbit_string_literal_7.data);
  return 0;
}

int32_t _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__executeN13handle__startS399(
  struct _M0TWEu* _M0L6_2aenvS875
) {
  struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399* _M0L14_2acasted__envS876;
  moonbit_string_t _M0L8filenameS401;
  int32_t _M0L5indexS403;
  moonbit_string_t _M0L10file__nameS400;
  struct _M0TPB13StringBuilder* _M0L18_2astring__builderS402;
  moonbit_string_t _M0L6_2atmpS877;
  #line 560 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L14_2acasted__envS876
  = (struct _M0R85_24re_2dmbt_2fre_2emoonbit__test__driver__internal__do__execute_2ehandle__start_7c399*)_M0L6_2aenvS875;
  _M0L8filenameS401 = _M0L14_2acasted__envS876->$1;
  _M0L5indexS403 = _M0L14_2acasted__envS876->$0;
  #line 561 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L10file__nameS400
  = _M0MPC16string6String14escape_2einner(_M0L8filenameS401, 1);
  #line 562 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0FPB7printlnGsE((moonbit_string_t)moonbit_string_literal_2.data);
  #line 564 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L18_2astring__builderS402
  = _M0MPB13StringBuilder21StringBuilder_2einner(33);
  #line 564 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS402, (moonbit_string_t)moonbit_string_literal_8.data);
  #line 564 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0MPB13StringBuilder13write__objectGsE(_M0L18_2astring__builderS402, _M0L10file__nameS400);
  moonbit_decref(_M0L10file__nameS400);
  #line 564 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS402, (moonbit_string_t)moonbit_string_literal_4.data);
  #line 564 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS402, _M0L5indexS403);
  #line 564 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS402, (moonbit_string_t)moonbit_string_literal_6.data);
  #line 564 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L6_2atmpS877
  = _M0MPB13StringBuilder10to__string(_M0L18_2astring__builderS402);
  moonbit_decref(_M0L18_2astring__builderS402);
  #line 563 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0FPB7printlnGsE(_M0L6_2atmpS877);
  moonbit_decref(_M0L6_2atmpS877);
  #line 566 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0FPB7printlnGsE((moonbit_string_t)moonbit_string_literal_7.data);
  return 0;
}

struct _M0TPB5ArrayGUsiEE* _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__args(
  
) {
  int32_t _M0L45moonbit__test__driver__internal__parse__int__S356;
  int32_t _M0L61moonbit__test__driver__internal__utf8__bytes__to__mbt__stringS363;
  int32_t _M0L57moonbit__test__driver__internal__get__cli__args__internalS370;
  int32_t _M0L51moonbit__test__driver__internal__split__mbt__stringS377;
  struct _M0TUsiE** _M0L6_2atmpS874;
  struct _M0TPB5ArrayGUsiEE* _M0L16file__and__indexS384;
  struct _M0TPB5ArrayGsE* _M0L9cli__argsS385;
  moonbit_string_t _M0L6_2atmpS873;
  struct _M0TPB5ArrayGsE* _M0L10test__argsS386;
  int32_t _M0L7_2abindS387;
  int32_t _M0L2__S388;
  #line 232 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L45moonbit__test__driver__internal__parse__int__S356 = 0;
  _M0L61moonbit__test__driver__internal__utf8__bytes__to__mbt__stringS363 = 0;
  _M0L57moonbit__test__driver__internal__get__cli__args__internalS370
  = _M0L61moonbit__test__driver__internal__utf8__bytes__to__mbt__stringS363;
  _M0L51moonbit__test__driver__internal__split__mbt__stringS377 = 0;
  _M0L6_2atmpS874 = (struct _M0TUsiE**)moonbit_empty_ref_array;
  _M0L16file__and__indexS384
  = (struct _M0TPB5ArrayGUsiEE*)moonbit_malloc(sizeof(struct _M0TPB5ArrayGUsiEE));
  Moonbit_object_header(_M0L16file__and__indexS384)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 9, 0);
  _M0L16file__and__indexS384->$0 = _M0L6_2atmpS874;
  _M0L16file__and__indexS384->$1 = 0;
  #line 321 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L9cli__argsS385
  = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN57moonbit__test__driver__internal__get__cli__args__internalS370(_M0L57moonbit__test__driver__internal__get__cli__args__internalS370);
  #line 323 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L6_2atmpS873 = _M0MPC15array5Array2atGsE(_M0L9cli__argsS385, 1);
  moonbit_decref(_M0L9cli__argsS385);
  #line 322 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L10test__argsS386
  = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN51moonbit__test__driver__internal__split__mbt__stringS377(_M0L51moonbit__test__driver__internal__split__mbt__stringS377, _M0L6_2atmpS873, 47);
  moonbit_decref(_M0L6_2atmpS873);
  _M0L7_2abindS387 = _M0L10test__argsS386->$1;
  _M0L2__S388 = 0;
  while (1) {
    if (_M0L2__S388 < _M0L7_2abindS387) {
      moonbit_string_t* _M0L3bufS872 = _M0L10test__argsS386->$0;
      moonbit_string_t _M0L3argS389 =
        (moonbit_string_t)_M0L3bufS872[_M0L2__S388];
      struct _M0TPB5ArrayGsE* _M0L16file__and__rangeS390;
      moonbit_string_t _M0L4fileS391;
      moonbit_string_t _M0L5rangeS392;
      struct _M0TPB5ArrayGsE* _M0L15start__and__endS393;
      moonbit_string_t _M0L6_2atmpS870;
      int32_t _M0L5startS394;
      moonbit_string_t _M0L6_2atmpS869;
      int32_t _M0L3endS395;
      int32_t _M0L1iS396;
      int32_t _M0L6_2atmpS871;
      moonbit_incref(_M0L3argS389);
      #line 327 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L16file__and__rangeS390
      = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN51moonbit__test__driver__internal__split__mbt__stringS377(_M0L51moonbit__test__driver__internal__split__mbt__stringS377, _M0L3argS389, 58);
      moonbit_decref(_M0L3argS389);
      #line 328 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L4fileS391
      = _M0MPC15array5Array2atGsE(_M0L16file__and__rangeS390, 0);
      #line 329 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L5rangeS392
      = _M0MPC15array5Array2atGsE(_M0L16file__and__rangeS390, 1);
      moonbit_decref(_M0L16file__and__rangeS390);
      #line 330 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L15start__and__endS393
      = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN51moonbit__test__driver__internal__split__mbt__stringS377(_M0L51moonbit__test__driver__internal__split__mbt__stringS377, _M0L5rangeS392, 45);
      moonbit_decref(_M0L5rangeS392);
      #line 333 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L6_2atmpS870
      = _M0MPC15array5Array2atGsE(_M0L15start__and__endS393, 0);
      #line 333 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L5startS394
      = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN45moonbit__test__driver__internal__parse__int__S356(_M0L45moonbit__test__driver__internal__parse__int__S356, _M0L6_2atmpS870);
      moonbit_decref(_M0L6_2atmpS870);
      #line 334 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L6_2atmpS869
      = _M0MPC15array5Array2atGsE(_M0L15start__and__endS393, 1);
      moonbit_decref(_M0L15start__and__endS393);
      #line 334 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L3endS395
      = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN45moonbit__test__driver__internal__parse__int__S356(_M0L45moonbit__test__driver__internal__parse__int__S356, _M0L6_2atmpS869);
      moonbit_decref(_M0L6_2atmpS869);
      _M0L1iS396 = _M0L5startS394;
      while (1) {
        if (_M0L1iS396 < _M0L3endS395) {
          struct _M0TUsiE* _M0L8_2atupleS867;
          int32_t _M0L6_2atmpS868;
          moonbit_incref(_M0L4fileS391);
          _M0L8_2atupleS867
          = (struct _M0TUsiE*)moonbit_malloc(sizeof(struct _M0TUsiE));
          Moonbit_object_header(_M0L8_2atupleS867)->meta
          = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 12, 0);
          _M0L8_2atupleS867->$0 = _M0L4fileS391;
          _M0L8_2atupleS867->$1 = _M0L1iS396;
          #line 336 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
          _M0MPC15array5Array4pushGUsiEE(_M0L16file__and__indexS384, _M0L8_2atupleS867);
          moonbit_decref(_M0L8_2atupleS867);
          _M0L6_2atmpS868 = _M0L1iS396 + 1;
          _M0L1iS396 = _M0L6_2atmpS868;
          continue;
        } else {
          moonbit_decref(_M0L4fileS391);
        }
        break;
      }
      _M0L6_2atmpS871 = _M0L2__S388 + 1;
      _M0L2__S388 = _M0L6_2atmpS871;
      continue;
    } else {
      moonbit_decref(_M0L10test__argsS386);
    }
    break;
  }
  return _M0L16file__and__indexS384;
}

struct _M0TPB5ArrayGsE* _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN51moonbit__test__driver__internal__split__mbt__stringS377(
  int32_t _M0L6_2aenvS848,
  moonbit_string_t _M0L1sS378,
  int32_t _M0L3sepS379
) {
  moonbit_string_t* _M0L6_2atmpS866;
  struct _M0TPB5ArrayGsE* _M0L3resS380;
  struct _M0TPB8MutLocalGiE* _M0L1iS381;
  struct _M0TPB8MutLocalGiE* _M0L5startS382;
  int32_t _M0L3valS861;
  int32_t _M0L6_2atmpS862;
  #line 300 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L6_2atmpS866 = (moonbit_string_t*)moonbit_empty_ref_array;
  _M0L3resS380
  = (struct _M0TPB5ArrayGsE*)moonbit_malloc(sizeof(struct _M0TPB5ArrayGsE));
  Moonbit_object_header(_M0L3resS380)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 15, 0);
  _M0L3resS380->$0 = _M0L6_2atmpS866;
  _M0L3resS380->$1 = 0;
  _M0L1iS381
  = (struct _M0TPB8MutLocalGiE*)moonbit_malloc(sizeof(struct _M0TPB8MutLocalGiE));
  Moonbit_object_header(_M0L1iS381)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_SCALAR, 0, 0);
  _M0L1iS381->$0 = 0;
  _M0L5startS382
  = (struct _M0TPB8MutLocalGiE*)moonbit_malloc(sizeof(struct _M0TPB8MutLocalGiE));
  Moonbit_object_header(_M0L5startS382)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_SCALAR, 0, 0);
  _M0L5startS382->$0 = 0;
  while (1) {
    int32_t _M0L3valS849 = _M0L1iS381->$0;
    int32_t _M0L6_2atmpS850 = Moonbit_array_length(_M0L1sS378);
    if (_M0L3valS849 < _M0L6_2atmpS850) {
      int32_t _M0L3valS853 = _M0L1iS381->$0;
      int32_t _M0L6_2atmpS852;
      int32_t _M0L6_2atmpS851;
      int32_t _M0L3valS860;
      int32_t _M0L6_2atmpS859;
      if (
        _M0L3valS853 < 0 || _M0L3valS853 >= Moonbit_array_length(_M0L1sS378)
      ) {
        #line 308 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
        moonbit_panic();
      }
      _M0L6_2atmpS852 = _M0L1sS378[_M0L3valS853];
      _M0L6_2atmpS851 = _M0L6_2atmpS852;
      if (_M0L6_2atmpS851 == _M0L3sepS379) {
        int32_t _M0L3valS855 = _M0L5startS382->$0;
        int32_t _M0L3valS856 = _M0L1iS381->$0;
        moonbit_string_t _M0L6_2atmpS854;
        int32_t _M0L3valS858;
        int32_t _M0L6_2atmpS857;
        #line 309 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
        _M0L6_2atmpS854
        = _M0MPC16string6String17unsafe__substring(_M0L1sS378, _M0L3valS855, _M0L3valS856);
        #line 309 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
        _M0MPC15array5Array4pushGsE(_M0L3resS380, _M0L6_2atmpS854);
        moonbit_decref(_M0L6_2atmpS854);
        _M0L3valS858 = _M0L1iS381->$0;
        _M0L6_2atmpS857 = _M0L3valS858 + 1;
        _M0L5startS382->$0 = _M0L6_2atmpS857;
      }
      _M0L3valS860 = _M0L1iS381->$0;
      _M0L6_2atmpS859 = _M0L3valS860 + 1;
      _M0L1iS381->$0 = _M0L6_2atmpS859;
      continue;
    } else {
      moonbit_decref(_M0L1iS381);
    }
    break;
  }
  _M0L3valS861 = _M0L5startS382->$0;
  _M0L6_2atmpS862 = Moonbit_array_length(_M0L1sS378);
  if (_M0L3valS861 < _M0L6_2atmpS862) {
    int32_t _M0L3valS864 = _M0L5startS382->$0;
    int32_t _M0L6_2atmpS865;
    moonbit_string_t _M0L6_2atmpS863;
    moonbit_decref(_M0L5startS382);
    _M0L6_2atmpS865 = Moonbit_array_length(_M0L1sS378);
    #line 315 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
    _M0L6_2atmpS863
    = _M0MPC16string6String17unsafe__substring(_M0L1sS378, _M0L3valS864, _M0L6_2atmpS865);
    #line 315 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
    _M0MPC15array5Array4pushGsE(_M0L3resS380, _M0L6_2atmpS863);
    moonbit_decref(_M0L6_2atmpS863);
  } else {
    moonbit_decref(_M0L5startS382);
  }
  return _M0L3resS380;
}

struct _M0TPB5ArrayGsE* _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN57moonbit__test__driver__internal__get__cli__args__internalS370(
  int32_t _M0L61moonbit__test__driver__internal__utf8__bytes__to__mbt__stringS363
) {
  moonbit_bytes_t* _M0L3tmpS371;
  int32_t _M0L6_2atmpS847;
  struct _M0TPB5ArrayGsE* _M0L3resS372;
  int32_t _M0L7_2abindS373;
  int32_t _M0L7_2abindS374;
  int32_t _M0L1iS375;
  #line 289 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  #line 292 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L3tmpS371
  = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__get__cli__args__ffi();
  _M0L6_2atmpS847 = Moonbit_array_length(_M0L3tmpS371);
  #line 293 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L3resS372 = _M0MPC15array5Array11new_2einnerGsE(_M0L6_2atmpS847);
  _M0L7_2abindS373 = 0;
  _M0L7_2abindS374 = Moonbit_array_length(_M0L3tmpS371);
  _M0L1iS375 = _M0L7_2abindS373;
  while (1) {
    if (_M0L1iS375 < _M0L7_2abindS374) {
      moonbit_bytes_t _M0L6_2atmpS845;
      moonbit_string_t _M0L6_2atmpS844;
      int32_t _M0L6_2atmpS846;
      if (_M0L1iS375 < 0 || _M0L1iS375 >= Moonbit_array_length(_M0L3tmpS371)) {
        #line 295 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
        moonbit_panic();
      }
      _M0L6_2atmpS845 = (moonbit_bytes_t)_M0L3tmpS371[_M0L1iS375];
      moonbit_incref(_M0L6_2atmpS845);
      #line 295 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0L6_2atmpS844
      = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN61moonbit__test__driver__internal__utf8__bytes__to__mbt__stringS363(_M0L61moonbit__test__driver__internal__utf8__bytes__to__mbt__stringS363, _M0L6_2atmpS845);
      moonbit_decref(_M0L6_2atmpS845);
      #line 295 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0MPC15array5Array4pushGsE(_M0L3resS372, _M0L6_2atmpS844);
      moonbit_decref(_M0L6_2atmpS844);
      _M0L6_2atmpS846 = _M0L1iS375 + 1;
      _M0L1iS375 = _M0L6_2atmpS846;
      continue;
    } else {
      moonbit_decref(_M0L3tmpS371);
    }
    break;
  }
  return _M0L3resS372;
}

moonbit_string_t _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN61moonbit__test__driver__internal__utf8__bytes__to__mbt__stringS363(
  int32_t _M0L6_2aenvS758,
  moonbit_bytes_t _M0L5bytesS364
) {
  struct _M0TPB13StringBuilder* _M0L3resS365;
  int32_t _M0L3lenS366;
  struct _M0TPB8MutLocalGiE* _M0L1iS367;
  moonbit_string_t _result_962;
  #line 245 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  #line 248 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L3resS365 = _M0MPB13StringBuilder21StringBuilder_2einner(0);
  _M0L3lenS366 = Moonbit_array_length(_M0L5bytesS364);
  _M0L1iS367
  = (struct _M0TPB8MutLocalGiE*)moonbit_malloc(sizeof(struct _M0TPB8MutLocalGiE));
  Moonbit_object_header(_M0L1iS367)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_SCALAR, 0, 0);
  _M0L1iS367->$0 = 0;
  while (1) {
    int32_t _M0L3valS759 = _M0L1iS367->$0;
    if (_M0L3valS759 < _M0L3lenS366) {
      int32_t _M0L3valS843 = _M0L1iS367->$0;
      int32_t _M0L6_2atmpS842;
      int32_t _M0L6_2atmpS841;
      struct _M0TPB8MutLocalGiE* _M0L1cS368;
      int32_t _M0L3valS760;
      if (
        _M0L3valS843 < 0
        || _M0L3valS843 >= Moonbit_array_length(_M0L5bytesS364)
      ) {
        #line 252 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
        moonbit_panic();
      }
      _M0L6_2atmpS842 = _M0L5bytesS364[_M0L3valS843];
      _M0L6_2atmpS841 = (int32_t)_M0L6_2atmpS842;
      _M0L1cS368
      = (struct _M0TPB8MutLocalGiE*)moonbit_malloc(sizeof(struct _M0TPB8MutLocalGiE));
      Moonbit_object_header(_M0L1cS368)->meta
      = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_SCALAR, 0, 0);
      _M0L1cS368->$0 = _M0L6_2atmpS841;
      _M0L3valS760 = _M0L1cS368->$0;
      if (_M0L3valS760 < 128) {
        int32_t _M0L3valS762 = _M0L1cS368->$0;
        int32_t _M0L6_2atmpS761;
        int32_t _M0L3valS764;
        int32_t _M0L6_2atmpS763;
        moonbit_decref(_M0L1cS368);
        _M0L6_2atmpS761 = _M0L3valS762;
        #line 254 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
        _M0IPB13StringBuilderPB6Logger11write__char(_M0L3resS365, _M0L6_2atmpS761);
        _M0L3valS764 = _M0L1iS367->$0;
        _M0L6_2atmpS763 = _M0L3valS764 + 1;
        _M0L1iS367->$0 = _M0L6_2atmpS763;
      } else {
        int32_t _M0L3valS765 = _M0L1cS368->$0;
        if (_M0L3valS765 < 224) {
          int32_t _M0L3valS767 = _M0L1iS367->$0;
          int32_t _M0L6_2atmpS766 = _M0L3valS767 + 1;
          int32_t _M0L3valS776;
          int32_t _M0L6_2atmpS775;
          int32_t _M0L6_2atmpS769;
          int32_t _M0L3valS774;
          int32_t _M0L6_2atmpS773;
          int32_t _M0L6_2atmpS772;
          int32_t _M0L6_2atmpS771;
          int32_t _M0L6_2atmpS770;
          int32_t _M0L6_2atmpS768;
          int32_t _M0L3valS778;
          int32_t _M0L6_2atmpS777;
          int32_t _M0L3valS780;
          int32_t _M0L6_2atmpS779;
          if (_M0L6_2atmpS766 >= _M0L3lenS366) {
            moonbit_decref(_M0L1cS368);
            moonbit_decref(_M0L1iS367);
            break;
          }
          _M0L3valS776 = _M0L1cS368->$0;
          _M0L6_2atmpS775 = _M0L3valS776 & 31;
          _M0L6_2atmpS769 = _M0L6_2atmpS775 << 6;
          _M0L3valS774 = _M0L1iS367->$0;
          _M0L6_2atmpS773 = _M0L3valS774 + 1;
          if (
            _M0L6_2atmpS773 < 0
            || _M0L6_2atmpS773 >= Moonbit_array_length(_M0L5bytesS364)
          ) {
            #line 260 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
            moonbit_panic();
          }
          _M0L6_2atmpS772 = _M0L5bytesS364[_M0L6_2atmpS773];
          _M0L6_2atmpS771 = (int32_t)_M0L6_2atmpS772;
          _M0L6_2atmpS770 = _M0L6_2atmpS771 & 63;
          _M0L6_2atmpS768 = _M0L6_2atmpS769 | _M0L6_2atmpS770;
          _M0L1cS368->$0 = _M0L6_2atmpS768;
          _M0L3valS778 = _M0L1cS368->$0;
          moonbit_decref(_M0L1cS368);
          _M0L6_2atmpS777 = _M0L3valS778;
          #line 261 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
          _M0IPB13StringBuilderPB6Logger11write__char(_M0L3resS365, _M0L6_2atmpS777);
          _M0L3valS780 = _M0L1iS367->$0;
          _M0L6_2atmpS779 = _M0L3valS780 + 2;
          _M0L1iS367->$0 = _M0L6_2atmpS779;
        } else {
          int32_t _M0L3valS781 = _M0L1cS368->$0;
          if (_M0L3valS781 < 240) {
            int32_t _M0L3valS783 = _M0L1iS367->$0;
            int32_t _M0L6_2atmpS782 = _M0L3valS783 + 2;
            int32_t _M0L3valS799;
            int32_t _M0L6_2atmpS798;
            int32_t _M0L6_2atmpS791;
            int32_t _M0L3valS797;
            int32_t _M0L6_2atmpS796;
            int32_t _M0L6_2atmpS795;
            int32_t _M0L6_2atmpS794;
            int32_t _M0L6_2atmpS793;
            int32_t _M0L6_2atmpS792;
            int32_t _M0L6_2atmpS785;
            int32_t _M0L3valS790;
            int32_t _M0L6_2atmpS789;
            int32_t _M0L6_2atmpS788;
            int32_t _M0L6_2atmpS787;
            int32_t _M0L6_2atmpS786;
            int32_t _M0L6_2atmpS784;
            int32_t _M0L3valS801;
            int32_t _M0L6_2atmpS800;
            int32_t _M0L3valS803;
            int32_t _M0L6_2atmpS802;
            if (_M0L6_2atmpS782 >= _M0L3lenS366) {
              moonbit_decref(_M0L1cS368);
              moonbit_decref(_M0L1iS367);
              break;
            }
            _M0L3valS799 = _M0L1cS368->$0;
            _M0L6_2atmpS798 = _M0L3valS799 & 15;
            _M0L6_2atmpS791 = _M0L6_2atmpS798 << 12;
            _M0L3valS797 = _M0L1iS367->$0;
            _M0L6_2atmpS796 = _M0L3valS797 + 1;
            if (
              _M0L6_2atmpS796 < 0
              || _M0L6_2atmpS796 >= Moonbit_array_length(_M0L5bytesS364)
            ) {
              #line 268 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
              moonbit_panic();
            }
            _M0L6_2atmpS795 = _M0L5bytesS364[_M0L6_2atmpS796];
            _M0L6_2atmpS794 = (int32_t)_M0L6_2atmpS795;
            _M0L6_2atmpS793 = _M0L6_2atmpS794 & 63;
            _M0L6_2atmpS792 = _M0L6_2atmpS793 << 6;
            _M0L6_2atmpS785 = _M0L6_2atmpS791 | _M0L6_2atmpS792;
            _M0L3valS790 = _M0L1iS367->$0;
            _M0L6_2atmpS789 = _M0L3valS790 + 2;
            if (
              _M0L6_2atmpS789 < 0
              || _M0L6_2atmpS789 >= Moonbit_array_length(_M0L5bytesS364)
            ) {
              #line 269 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
              moonbit_panic();
            }
            _M0L6_2atmpS788 = _M0L5bytesS364[_M0L6_2atmpS789];
            _M0L6_2atmpS787 = (int32_t)_M0L6_2atmpS788;
            _M0L6_2atmpS786 = _M0L6_2atmpS787 & 63;
            _M0L6_2atmpS784 = _M0L6_2atmpS785 | _M0L6_2atmpS786;
            _M0L1cS368->$0 = _M0L6_2atmpS784;
            _M0L3valS801 = _M0L1cS368->$0;
            moonbit_decref(_M0L1cS368);
            _M0L6_2atmpS800 = _M0L3valS801;
            #line 270 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
            _M0IPB13StringBuilderPB6Logger11write__char(_M0L3resS365, _M0L6_2atmpS800);
            _M0L3valS803 = _M0L1iS367->$0;
            _M0L6_2atmpS802 = _M0L3valS803 + 3;
            _M0L1iS367->$0 = _M0L6_2atmpS802;
          } else {
            int32_t _M0L3valS805 = _M0L1iS367->$0;
            int32_t _M0L6_2atmpS804 = _M0L3valS805 + 3;
            int32_t _M0L3valS828;
            int32_t _M0L6_2atmpS827;
            int32_t _M0L6_2atmpS820;
            int32_t _M0L3valS826;
            int32_t _M0L6_2atmpS825;
            int32_t _M0L6_2atmpS824;
            int32_t _M0L6_2atmpS823;
            int32_t _M0L6_2atmpS822;
            int32_t _M0L6_2atmpS821;
            int32_t _M0L6_2atmpS813;
            int32_t _M0L3valS819;
            int32_t _M0L6_2atmpS818;
            int32_t _M0L6_2atmpS817;
            int32_t _M0L6_2atmpS816;
            int32_t _M0L6_2atmpS815;
            int32_t _M0L6_2atmpS814;
            int32_t _M0L6_2atmpS807;
            int32_t _M0L3valS812;
            int32_t _M0L6_2atmpS811;
            int32_t _M0L6_2atmpS810;
            int32_t _M0L6_2atmpS809;
            int32_t _M0L6_2atmpS808;
            int32_t _M0L6_2atmpS806;
            int32_t _M0L3valS830;
            int32_t _M0L6_2atmpS829;
            int32_t _M0L3valS834;
            int32_t _M0L6_2atmpS833;
            int32_t _M0L6_2atmpS832;
            int32_t _M0L6_2atmpS831;
            int32_t _M0L3valS838;
            int32_t _M0L6_2atmpS837;
            int32_t _M0L6_2atmpS836;
            int32_t _M0L6_2atmpS835;
            int32_t _M0L3valS840;
            int32_t _M0L6_2atmpS839;
            if (_M0L6_2atmpS804 >= _M0L3lenS366) {
              moonbit_decref(_M0L1cS368);
              moonbit_decref(_M0L1iS367);
              break;
            }
            _M0L3valS828 = _M0L1cS368->$0;
            _M0L6_2atmpS827 = _M0L3valS828 & 7;
            _M0L6_2atmpS820 = _M0L6_2atmpS827 << 18;
            _M0L3valS826 = _M0L1iS367->$0;
            _M0L6_2atmpS825 = _M0L3valS826 + 1;
            if (
              _M0L6_2atmpS825 < 0
              || _M0L6_2atmpS825 >= Moonbit_array_length(_M0L5bytesS364)
            ) {
              #line 277 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
              moonbit_panic();
            }
            _M0L6_2atmpS824 = _M0L5bytesS364[_M0L6_2atmpS825];
            _M0L6_2atmpS823 = (int32_t)_M0L6_2atmpS824;
            _M0L6_2atmpS822 = _M0L6_2atmpS823 & 63;
            _M0L6_2atmpS821 = _M0L6_2atmpS822 << 12;
            _M0L6_2atmpS813 = _M0L6_2atmpS820 | _M0L6_2atmpS821;
            _M0L3valS819 = _M0L1iS367->$0;
            _M0L6_2atmpS818 = _M0L3valS819 + 2;
            if (
              _M0L6_2atmpS818 < 0
              || _M0L6_2atmpS818 >= Moonbit_array_length(_M0L5bytesS364)
            ) {
              #line 278 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
              moonbit_panic();
            }
            _M0L6_2atmpS817 = _M0L5bytesS364[_M0L6_2atmpS818];
            _M0L6_2atmpS816 = (int32_t)_M0L6_2atmpS817;
            _M0L6_2atmpS815 = _M0L6_2atmpS816 & 63;
            _M0L6_2atmpS814 = _M0L6_2atmpS815 << 6;
            _M0L6_2atmpS807 = _M0L6_2atmpS813 | _M0L6_2atmpS814;
            _M0L3valS812 = _M0L1iS367->$0;
            _M0L6_2atmpS811 = _M0L3valS812 + 3;
            if (
              _M0L6_2atmpS811 < 0
              || _M0L6_2atmpS811 >= Moonbit_array_length(_M0L5bytesS364)
            ) {
              #line 279 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
              moonbit_panic();
            }
            _M0L6_2atmpS810 = _M0L5bytesS364[_M0L6_2atmpS811];
            _M0L6_2atmpS809 = (int32_t)_M0L6_2atmpS810;
            _M0L6_2atmpS808 = _M0L6_2atmpS809 & 63;
            _M0L6_2atmpS806 = _M0L6_2atmpS807 | _M0L6_2atmpS808;
            _M0L1cS368->$0 = _M0L6_2atmpS806;
            _M0L3valS830 = _M0L1cS368->$0;
            _M0L6_2atmpS829 = _M0L3valS830 - 65536;
            _M0L1cS368->$0 = _M0L6_2atmpS829;
            _M0L3valS834 = _M0L1cS368->$0;
            _M0L6_2atmpS833 = _M0L3valS834 >> 10;
            _M0L6_2atmpS832 = _M0L6_2atmpS833 + 55296;
            _M0L6_2atmpS831 = _M0L6_2atmpS832;
            #line 281 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
            _M0IPB13StringBuilderPB6Logger11write__char(_M0L3resS365, _M0L6_2atmpS831);
            _M0L3valS838 = _M0L1cS368->$0;
            moonbit_decref(_M0L1cS368);
            _M0L6_2atmpS837 = _M0L3valS838 & 1023;
            _M0L6_2atmpS836 = _M0L6_2atmpS837 + 56320;
            _M0L6_2atmpS835 = _M0L6_2atmpS836;
            #line 282 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
            _M0IPB13StringBuilderPB6Logger11write__char(_M0L3resS365, _M0L6_2atmpS835);
            _M0L3valS840 = _M0L1iS367->$0;
            _M0L6_2atmpS839 = _M0L3valS840 + 4;
            _M0L1iS367->$0 = _M0L6_2atmpS839;
          }
        }
      }
      continue;
    } else {
      moonbit_decref(_M0L1iS367);
    }
    break;
  }
  #line 286 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _result_962 = _M0MPB13StringBuilder10to__string(_M0L3resS365);
  moonbit_decref(_M0L3resS365);
  return _result_962;
}

int32_t _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__argsN45moonbit__test__driver__internal__parse__int__S356(
  int32_t _M0L6_2aenvS751,
  moonbit_string_t _M0L1sS357
) {
  struct _M0TPB8MutLocalGiE* _M0L3resS358;
  int32_t _M0L3lenS359;
  int32_t _M0L7_2abindS360;
  int32_t _M0L1iS361;
  int32_t _result_964;
  #line 236 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L3resS358
  = (struct _M0TPB8MutLocalGiE*)moonbit_malloc(sizeof(struct _M0TPB8MutLocalGiE));
  Moonbit_object_header(_M0L3resS358)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_SCALAR, 0, 0);
  _M0L3resS358->$0 = 0;
  _M0L3lenS359 = Moonbit_array_length(_M0L1sS357);
  _M0L7_2abindS360 = 0;
  _M0L1iS361 = _M0L7_2abindS360;
  while (1) {
    if (_M0L1iS361 < _M0L3lenS359) {
      int32_t _M0L3valS756 = _M0L3resS358->$0;
      int32_t _M0L6_2atmpS753 = _M0L3valS756 * 10;
      int32_t _M0L6_2atmpS755;
      int32_t _M0L6_2atmpS754;
      int32_t _M0L6_2atmpS752;
      int32_t _M0L6_2atmpS757;
      if (_M0L1iS361 < 0 || _M0L1iS361 >= Moonbit_array_length(_M0L1sS357)) {
        #line 240 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
        moonbit_panic();
      }
      _M0L6_2atmpS755 = _M0L1sS357[_M0L1iS361];
      _M0L6_2atmpS754 = _M0L6_2atmpS755 - 48;
      _M0L6_2atmpS752 = _M0L6_2atmpS753 + _M0L6_2atmpS754;
      _M0L3resS358->$0 = _M0L6_2atmpS752;
      _M0L6_2atmpS757 = _M0L1iS361 + 1;
      _M0L1iS361 = _M0L6_2atmpS757;
      continue;
    }
    break;
  }
  _result_964 = _M0L3resS358->$0;
  moonbit_decref(_M0L3resS358);
  return _result_964;
}

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re41MoonBit__Test__Driver__Internal__No__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE* _M0L12_2adiscard__S326,
  moonbit_string_t _M0L12_2adiscard__S327,
  int32_t _M0L12_2adiscard__S328,
  struct _M0TWEu* _M0L12_2adiscard__S329,
  struct _M0TWssbEu* _M0L12_2adiscard__S330,
  struct _M0TWRPC15error5ErrorEs* _M0L12_2adiscard__S331
) {
  struct moonbit_result_0 _result_965;
  #line 35 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _result_965.tag = 1;
  _result_965.data.ok = 0;
  return _result_965;
}

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re43MoonBit__Test__Driver__Internal__With__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE* _M0L12_2adiscard__S332,
  moonbit_string_t _M0L12_2adiscard__S333,
  int32_t _M0L12_2adiscard__S334,
  struct _M0TWEu* _M0L12_2adiscard__S335,
  struct _M0TWssbEu* _M0L12_2adiscard__S336,
  struct _M0TWRPC15error5ErrorEs* _M0L12_2adiscard__S337
) {
  struct moonbit_result_0 _result_966;
  #line 35 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _result_966.tag = 1;
  _result_966.data.ok = 0;
  return _result_966;
}

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re48MoonBit__Test__Driver__Internal__Async__No__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE* _M0L12_2adiscard__S338,
  moonbit_string_t _M0L12_2adiscard__S339,
  int32_t _M0L12_2adiscard__S340,
  struct _M0TWEu* _M0L12_2adiscard__S341,
  struct _M0TWssbEu* _M0L12_2adiscard__S342,
  struct _M0TWRPC15error5ErrorEs* _M0L12_2adiscard__S343
) {
  struct moonbit_result_0 _result_967;
  #line 35 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _result_967.tag = 1;
  _result_967.data.ok = 0;
  return _result_967;
}

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re50MoonBit__Test__Driver__Internal__Async__With__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE* _M0L12_2adiscard__S344,
  moonbit_string_t _M0L12_2adiscard__S345,
  int32_t _M0L12_2adiscard__S346,
  struct _M0TWEu* _M0L12_2adiscard__S347,
  struct _M0TWssbEu* _M0L12_2adiscard__S348,
  struct _M0TWRPC15error5ErrorEs* _M0L12_2adiscard__S349
) {
  struct moonbit_result_0 _result_968;
  #line 35 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _result_968.tag = 1;
  _result_968.data.ok = 0;
  return _result_968;
}

struct moonbit_result_0 _M0IP016_24default__implP28re_2dmbt2re21MoonBit__Test__Driver9run__testGRP28re_2dmbt2re50MoonBit__Test__Driver__Internal__With__Bench__ArgsE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE* _M0L12_2adiscard__S350,
  moonbit_string_t _M0L12_2adiscard__S351,
  int32_t _M0L12_2adiscard__S352,
  struct _M0TWEu* _M0L12_2adiscard__S353,
  struct _M0TWssbEu* _M0L12_2adiscard__S354,
  struct _M0TWRPC15error5ErrorEs* _M0L12_2adiscard__S355
) {
  struct moonbit_result_0 _result_969;
  #line 35 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _result_969.tag = 1;
  _result_969.data.ok = 0;
  return _result_969;
}

int32_t _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver20is__being__cancelledGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE(
  
) {
  #line 17 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  return 0;
}

int32_t _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver17run__async__testsGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE(
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE* _M0L12_2adiscard__S325
) {
  #line 12 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  return 0;
}

moonbit_string_t _M0MPC15array5Array2atGsE(
  struct _M0TPB5ArrayGsE* _M0L4selfS323,
  int32_t _M0L5indexS324
) {
  int32_t _M0L3lenS322;
  int32_t _if__result_970;
  #line 181 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\array.mbt"
  _M0L3lenS322 = _M0L4selfS323->$1;
  if (_M0L5indexS324 >= 0) {
    _if__result_970 = _M0L5indexS324 < _M0L3lenS322;
  } else {
    _if__result_970 = 0;
  }
  if (_if__result_970) {
    moonbit_string_t* _M0L6_2atmpS750;
    moonbit_string_t _M0L6_2atmpS899;
    #line 186 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\array.mbt"
    _M0L6_2atmpS750 = _M0MPC15array5Array6bufferGsE(_M0L4selfS323);
    _M0L6_2atmpS899 = (moonbit_string_t)_M0L6_2atmpS750[_M0L5indexS324];
    moonbit_incref(_M0L6_2atmpS899);
    moonbit_decref(_M0L6_2atmpS750);
    return _M0L6_2atmpS899;
  } else {
    #line 185 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\array.mbt"
    moonbit_panic();
  }
}

int32_t _M0FPB7printlnGsE(moonbit_string_t _M0L5inputS321) {
  moonbit_string_t _M0L6_2atmpS749;
  #line 36 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\console.mbt"
  #line 37 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\console.mbt"
  _M0L6_2atmpS749 = _M0IPC16string6StringPB4Show10to__string(_M0L5inputS321);
  #line 37 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\console.mbt"
  moonbit_println(_M0L6_2atmpS749);
  moonbit_decref(_M0L6_2atmpS749);
  return 0;
}

moonbit_string_t _M0IPC13int3IntPB4Show10to__string(int32_t _M0L4selfS320) {
  #line 35 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  #line 36 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  return _M0MPC13int3Int18to__string_2einner(_M0L4selfS320, 10);
}

int32_t _M0MPC15array5Array4pushGsE(
  struct _M0TPB5ArrayGsE* _M0L4selfS314,
  moonbit_string_t _M0L5valueS316
) {
  int32_t _M0L3lenS739;
  moonbit_string_t* _M0L6_2atmpS741;
  int32_t _M0L6_2atmpS740;
  int32_t _M0L6lengthS315;
  moonbit_string_t* _M0L3bufS742;
  moonbit_string_t _M0L6_2aoldS900;
  int32_t _M0L6_2atmpS743;
  #line 305 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L3lenS739 = _M0L4selfS314->$1;
  #line 306 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L6_2atmpS741 = _M0MPC15array5Array6bufferGsE(_M0L4selfS314);
  _M0L6_2atmpS740 = Moonbit_array_length(_M0L6_2atmpS741);
  moonbit_decref(_M0L6_2atmpS741);
  if (_M0L3lenS739 == _M0L6_2atmpS740) {
    #line 307 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
    _M0MPC15array5Array7reallocGsE(_M0L4selfS314);
  }
  _M0L6lengthS315 = _M0L4selfS314->$1;
  _M0L3bufS742 = _M0L4selfS314->$0;
  _M0L6_2aoldS900 = (moonbit_string_t)_M0L3bufS742[_M0L6lengthS315];
  moonbit_incref(_M0L5valueS316);
  moonbit_decref(_M0L6_2aoldS900);
  _M0L3bufS742[_M0L6lengthS315] = _M0L5valueS316;
  _M0L6_2atmpS743 = _M0L6lengthS315 + 1;
  _M0L4selfS314->$1 = _M0L6_2atmpS743;
  return 0;
}

int32_t _M0MPC15array5Array4pushGUsiEE(
  struct _M0TPB5ArrayGUsiEE* _M0L4selfS317,
  struct _M0TUsiE* _M0L5valueS319
) {
  int32_t _M0L3lenS744;
  struct _M0TUsiE** _M0L6_2atmpS746;
  int32_t _M0L6_2atmpS745;
  int32_t _M0L6lengthS318;
  struct _M0TUsiE** _M0L3bufS747;
  struct _M0TUsiE* _M0L6_2aoldS902;
  int32_t _M0L6_2atmpS748;
  #line 305 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L3lenS744 = _M0L4selfS317->$1;
  #line 306 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L6_2atmpS746 = _M0MPC15array5Array6bufferGUsiEE(_M0L4selfS317);
  _M0L6_2atmpS745 = Moonbit_array_length(_M0L6_2atmpS746);
  moonbit_decref(_M0L6_2atmpS746);
  if (_M0L3lenS744 == _M0L6_2atmpS745) {
    #line 307 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
    _M0MPC15array5Array7reallocGUsiEE(_M0L4selfS317);
  }
  _M0L6lengthS318 = _M0L4selfS317->$1;
  _M0L3bufS747 = _M0L4selfS317->$0;
  _M0L6_2aoldS902 = (struct _M0TUsiE*)_M0L3bufS747[_M0L6lengthS318];
  moonbit_incref(_M0L5valueS319);
  if (_M0L6_2aoldS902) {
    moonbit_decref(_M0L6_2aoldS902);
  }
  _M0L3bufS747[_M0L6lengthS318] = _M0L5valueS319;
  _M0L6_2atmpS748 = _M0L6lengthS318 + 1;
  _M0L4selfS317->$1 = _M0L6_2atmpS748;
  return 0;
}

int32_t _M0MPC15array5Array7reallocGsE(struct _M0TPB5ArrayGsE* _M0L4selfS309) {
  int32_t _M0L8old__capS308;
  int32_t _M0L8new__capS310;
  #line 245 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L8old__capS308 = _M0L4selfS309->$1;
  if (_M0L8old__capS308 == 0) {
    _M0L8new__capS310 = 8;
  } else {
    _M0L8new__capS310 = _M0L8old__capS308 * 2;
  }
  #line 248 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0MPC15array5Array14resize__bufferGsE(_M0L4selfS309, _M0L8new__capS310);
  return 0;
}

int32_t _M0MPC15array5Array7reallocGUsiEE(
  struct _M0TPB5ArrayGUsiEE* _M0L4selfS312
) {
  int32_t _M0L8old__capS311;
  int32_t _M0L8new__capS313;
  #line 245 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L8old__capS311 = _M0L4selfS312->$1;
  if (_M0L8old__capS311 == 0) {
    _M0L8new__capS313 = 8;
  } else {
    _M0L8new__capS313 = _M0L8old__capS311 * 2;
  }
  #line 248 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0MPC15array5Array14resize__bufferGUsiEE(_M0L4selfS312, _M0L8new__capS313);
  return 0;
}

int32_t _M0MPC15array5Array14resize__bufferGsE(
  struct _M0TPB5ArrayGsE* _M0L4selfS297,
  int32_t _M0L13new__capacityS300
) {
  moonbit_string_t* _M0L8old__bufS296;
  int32_t _M0L8old__capS298;
  int32_t _M0L9copy__lenS299;
  moonbit_string_t* _M0L8new__bufS301;
  moonbit_string_t* _M0L6_2aoldS904;
  #line 189 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L8old__bufS296 = _M0L4selfS297->$0;
  _M0L8old__capS298 = Moonbit_array_length(_M0L8old__bufS296);
  if (_M0L8old__capS298 < _M0L13new__capacityS300) {
    _M0L9copy__lenS299 = _M0L8old__capS298;
  } else {
    _M0L9copy__lenS299 = _M0L13new__capacityS300;
  }
  moonbit_incref(_M0L8old__bufS296);
  #line 193 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L8new__bufS301
  = _M0MPB18UninitializedArray23make__and__blit_2einnerGsE(_M0L8old__bufS296, _M0L13new__capacityS300, _M0L9copy__lenS299, 0, 0);
  moonbit_decref(_M0L8old__bufS296);
  _M0L6_2aoldS904 = _M0L4selfS297->$0;
  moonbit_decref(_M0L6_2aoldS904);
  _M0L4selfS297->$0 = _M0L8new__bufS301;
  return 0;
}

int32_t _M0MPC15array5Array14resize__bufferGUsiEE(
  struct _M0TPB5ArrayGUsiEE* _M0L4selfS303,
  int32_t _M0L13new__capacityS306
) {
  struct _M0TUsiE** _M0L8old__bufS302;
  int32_t _M0L8old__capS304;
  int32_t _M0L9copy__lenS305;
  struct _M0TUsiE** _M0L8new__bufS307;
  struct _M0TUsiE** _M0L6_2aoldS906;
  #line 189 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L8old__bufS302 = _M0L4selfS303->$0;
  _M0L8old__capS304 = Moonbit_array_length(_M0L8old__bufS302);
  if (_M0L8old__capS304 < _M0L13new__capacityS306) {
    _M0L9copy__lenS305 = _M0L8old__capS304;
  } else {
    _M0L9copy__lenS305 = _M0L13new__capacityS306;
  }
  moonbit_incref(_M0L8old__bufS302);
  #line 193 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L8new__bufS307
  = _M0MPB18UninitializedArray23make__and__blit_2einnerGUsiEE(_M0L8old__bufS302, _M0L13new__capacityS306, _M0L9copy__lenS305, 0, 0);
  moonbit_decref(_M0L8old__bufS302);
  _M0L6_2aoldS906 = _M0L4selfS303->$0;
  moonbit_decref(_M0L6_2aoldS906);
  _M0L4selfS303->$0 = _M0L8new__bufS307;
  return 0;
}

moonbit_string_t* _M0MPC15array5Array6bufferGsE(
  struct _M0TPB5ArrayGsE* _M0L4selfS294
) {
  moonbit_string_t* _M0L8_2afieldS908;
  #line 184 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L8_2afieldS908 = _M0L4selfS294->$0;
  moonbit_incref(_M0L8_2afieldS908);
  return _M0L8_2afieldS908;
}

struct _M0TUsiE** _M0MPC15array5Array6bufferGUsiEE(
  struct _M0TPB5ArrayGUsiEE* _M0L4selfS295
) {
  struct _M0TUsiE** _M0L8_2afieldS909;
  #line 184 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  _M0L8_2afieldS909 = _M0L4selfS295->$0;
  moonbit_incref(_M0L8_2afieldS909);
  return _M0L8_2afieldS909;
}

struct _M0TPB5ArrayGsE* _M0MPC15array5Array11new_2einnerGsE(
  int32_t _M0L8capacityS293
) {
  #line 113 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\arraycore_nonjs.mbt"
  if (_M0L8capacityS293 == 0) {
    moonbit_string_t* _M0L6_2atmpS737 =
      (moonbit_string_t*)moonbit_empty_ref_array;
    struct _M0TPB5ArrayGsE* _block_971 =
      (struct _M0TPB5ArrayGsE*)moonbit_malloc(sizeof(struct _M0TPB5ArrayGsE));
    Moonbit_object_header(_block_971)->meta
    = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 15, 0);
    _block_971->$0 = _M0L6_2atmpS737;
    _block_971->$1 = 0;
    return _block_971;
  } else {
    moonbit_string_t* _M0L6_2atmpS738 =
      (moonbit_string_t*)moonbit_make_ref_array(_M0L8capacityS293, (moonbit_string_t)moonbit_string_literal_0.data);
    struct _M0TPB5ArrayGsE* _block_972 =
      (struct _M0TPB5ArrayGsE*)moonbit_malloc(sizeof(struct _M0TPB5ArrayGsE));
    Moonbit_object_header(_block_972)->meta
    = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 15, 0);
    _block_972->$0 = _M0L6_2atmpS738;
    _block_972->$1 = 0;
    return _block_972;
  }
}

moonbit_string_t _M0IPC16string6StringPB4Show10to__string(
  moonbit_string_t _M0L4selfS292
) {
  #line 222 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  moonbit_incref(_M0L4selfS292);
  return _M0L4selfS292;
}

int32_t _M0IPB13StringBuilderPB6Logger11write__view(
  struct _M0TPB13StringBuilder* _M0L4selfS291,
  struct _M0TPC16string10StringView _M0L3strS290
) {
  int32_t _M0L3endS735;
  int32_t _M0L5startS736;
  int32_t _M0L8str__lenS289;
  int32_t _M0L3lenS728;
  int32_t _M0L6_2atmpS727;
  uint16_t* _M0L4dataS729;
  int32_t _M0L3lenS730;
  moonbit_string_t _M0L6_2atmpS731;
  int32_t _M0L6_2atmpS732;
  int32_t _M0L3lenS734;
  int32_t _M0L6_2atmpS733;
  #line 134 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L3endS735 = _M0L3strS290.$2;
  _M0L5startS736 = _M0L3strS290.$1;
  _M0L8str__lenS289 = _M0L3endS735 - _M0L5startS736;
  if (_M0L8str__lenS289 == 0) {
    return 0;
  }
  _M0L3lenS728 = _M0L4selfS291->$1;
  _M0L6_2atmpS727 = _M0L3lenS728 + _M0L8str__lenS289;
  #line 142 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0MPB13StringBuilder19grow__if__necessary(_M0L4selfS291, _M0L6_2atmpS727);
  _M0L4dataS729 = _M0L4selfS291->$0;
  _M0L3lenS730 = _M0L4selfS291->$1;
  moonbit_incref(_M0L4dataS729);
  #line 145 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L6_2atmpS731 = _M0MPC16string10StringView4data(_M0L3strS290);
  #line 146 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L6_2atmpS732 = _M0MPC16string10StringView13start__offset(_M0L3strS290);
  #line 143 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0MPC15array10FixedArray26unsafe__blit__from__string(_M0L4dataS729, _M0L3lenS730, _M0L6_2atmpS731, _M0L6_2atmpS732, _M0L8str__lenS289);
  moonbit_decref(_M0L4dataS729);
  moonbit_decref(_M0L6_2atmpS731);
  _M0L3lenS734 = _M0L4selfS291->$1;
  _M0L6_2atmpS733 = _M0L3lenS734 + _M0L8str__lenS289;
  _M0L4selfS291->$1 = _M0L6_2atmpS733;
  return 0;
}

moonbit_string_t _M0MPC16string6String17unsafe__substring(
  moonbit_string_t _M0L3strS286,
  int32_t _M0L5startS284,
  int32_t _M0L3endS285
) {
  int32_t _if__result_973;
  int32_t _M0L3lenS287;
  int32_t _M0L6_2atmpS725;
  int32_t _M0L6_2atmpS726;
  moonbit_bytes_t _M0L5bytesS288;
  moonbit_bytes_t _M0L6_2atmpS724;
  moonbit_string_t _result_974;
  #line 91 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\string.mbt"
  if (_M0L5startS284 == 0) {
    int32_t _M0L6_2atmpS723 = Moonbit_array_length(_M0L3strS286);
    _if__result_973 = _M0L3endS285 == _M0L6_2atmpS723;
  } else {
    _if__result_973 = 0;
  }
  if (_if__result_973) {
    moonbit_incref(_M0L3strS286);
    return _M0L3strS286;
  }
  _M0L3lenS287 = _M0L3endS285 - _M0L5startS284;
  _M0L6_2atmpS725 = _M0L3lenS287 * 2;
  #line 101 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\string.mbt"
  _M0L6_2atmpS726 = _M0IPC14byte4BytePB7Default7default();
  _M0L5bytesS288
  = (moonbit_bytes_t)moonbit_make_bytes(_M0L6_2atmpS725, _M0L6_2atmpS726);
  #line 102 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\string.mbt"
  _M0MPC15array10FixedArray18blit__from__string(_M0L5bytesS288, 0, _M0L3strS286, _M0L5startS284, _M0L3lenS287);
  _M0L6_2atmpS724 = _M0L5bytesS288;
  #line 103 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\string.mbt"
  _result_974
  = _M0MPC15bytes5Bytes29to__unchecked__string_2einner(_M0L6_2atmpS724, 0, 4294967296ll);
  moonbit_decref(_M0L6_2atmpS724);
  return _result_974;
}

int32_t _M0IPC14byte4BytePB7Default7default() {
  #line 231 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\byte.mbt"
  return 0;
}

moonbit_string_t _M0MPC15bytes5Bytes29to__unchecked__string_2einner(
  moonbit_bytes_t _M0L4selfS279,
  int32_t _M0L6offsetS283,
  int64_t _M0L6lengthS281
) {
  int32_t _M0L3lenS278;
  int32_t _M0L6lengthS280;
  int32_t _if__result_975;
  #line 77 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
  _M0L3lenS278 = Moonbit_array_length(_M0L4selfS279);
  if (_M0L6lengthS281 == 4294967296ll) {
    _M0L6lengthS280 = _M0L3lenS278 - _M0L6offsetS283;
  } else {
    int64_t _M0L7_2aSomeS282 = _M0L6lengthS281;
    _M0L6lengthS280 = (int32_t)_M0L7_2aSomeS282;
  }
  if (_M0L6offsetS283 >= 0) {
    if (_M0L6lengthS280 >= 0) {
      int32_t _M0L6_2atmpS722 = _M0L6offsetS283 + _M0L6lengthS280;
      _if__result_975 = _M0L6_2atmpS722 <= _M0L3lenS278;
    } else {
      _if__result_975 = 0;
    }
  } else {
    _if__result_975 = 0;
  }
  if (_if__result_975) {
    moonbit_incref(_M0L4selfS279);
    #line 85 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
    return _M0FPB19unsafe__sub__string(_M0L4selfS279, _M0L6offsetS283, _M0L6lengthS280);
  } else {
    #line 84 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
    moonbit_panic();
  }
}

int32_t _M0MPC15array10FixedArray18blit__from__string(
  moonbit_bytes_t _M0L4selfS270,
  int32_t _M0L13bytes__offsetS265,
  moonbit_string_t _M0L3strS272,
  int32_t _M0L11str__offsetS268,
  int32_t _M0L6lengthS266
) {
  int32_t _M0L6_2atmpS721;
  int32_t _M0L6_2atmpS720;
  int32_t _M0L2e1S264;
  int32_t _M0L6_2atmpS719;
  int32_t _M0L2e2S267;
  int32_t _M0L4len1S269;
  int32_t _M0L4len2S271;
  int32_t _if__result_976;
  #line 125 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
  _M0L6_2atmpS721 = _M0L6lengthS266 * 2;
  _M0L6_2atmpS720 = _M0L13bytes__offsetS265 + _M0L6_2atmpS721;
  _M0L2e1S264 = _M0L6_2atmpS720 - 1;
  _M0L6_2atmpS719 = _M0L11str__offsetS268 + _M0L6lengthS266;
  _M0L2e2S267 = _M0L6_2atmpS719 - 1;
  _M0L4len1S269 = Moonbit_array_length(_M0L4selfS270);
  _M0L4len2S271 = Moonbit_array_length(_M0L3strS272);
  if (_M0L6lengthS266 >= 0) {
    if (_M0L13bytes__offsetS265 >= 0) {
      if (_M0L2e1S264 < _M0L4len1S269) {
        if (_M0L11str__offsetS268 >= 0) {
          _if__result_976 = _M0L2e2S267 < _M0L4len2S271;
        } else {
          _if__result_976 = 0;
        }
      } else {
        _if__result_976 = 0;
      }
    } else {
      _if__result_976 = 0;
    }
  } else {
    _if__result_976 = 0;
  }
  if (_if__result_976) {
    int32_t _M0L16end__str__offsetS273 =
      _M0L11str__offsetS268 + _M0L6lengthS266;
    int32_t _M0L1iS274 = _M0L11str__offsetS268;
    int32_t _M0L1jS275 = _M0L13bytes__offsetS265;
    while (1) {
      if (_M0L1iS274 < _M0L16end__str__offsetS273) {
        int32_t _M0L6_2atmpS716 = _M0L3strS272[_M0L1iS274];
        int32_t _M0L6_2atmpS715 = (int32_t)_M0L6_2atmpS716;
        uint32_t _M0L1cS276 = *(uint32_t*)&_M0L6_2atmpS715;
        uint32_t _M0L6_2atmpS711 = _M0L1cS276 & 255u;
        int32_t _M0L6_2atmpS710;
        int32_t _M0L6_2atmpS712;
        uint32_t _M0L6_2atmpS714;
        int32_t _M0L6_2atmpS713;
        int32_t _M0L6_2atmpS717;
        int32_t _M0L6_2atmpS718;
        #line 142 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
        _M0L6_2atmpS710 = _M0MPC14uint4UInt8to__byte(_M0L6_2atmpS711);
        if (
          _M0L1jS275 < 0 || _M0L1jS275 >= Moonbit_array_length(_M0L4selfS270)
        ) {
          #line 142 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
          moonbit_panic();
        }
        _M0L4selfS270[_M0L1jS275] = _M0L6_2atmpS710;
        _M0L6_2atmpS712 = _M0L1jS275 + 1;
        _M0L6_2atmpS714 = _M0L1cS276 >> 8;
        #line 143 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
        _M0L6_2atmpS713 = _M0MPC14uint4UInt8to__byte(_M0L6_2atmpS714);
        if (
          _M0L6_2atmpS712 < 0
          || _M0L6_2atmpS712 >= Moonbit_array_length(_M0L4selfS270)
        ) {
          #line 143 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
          moonbit_panic();
        }
        _M0L4selfS270[_M0L6_2atmpS712] = _M0L6_2atmpS713;
        _M0L6_2atmpS717 = _M0L1iS274 + 1;
        _M0L6_2atmpS718 = _M0L1jS275 + 2;
        _M0L1iS274 = _M0L6_2atmpS717;
        _M0L1jS275 = _M0L6_2atmpS718;
        continue;
      }
      break;
    }
  } else {
    #line 138 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\bytes.mbt"
    moonbit_panic();
  }
  return 0;
}

int32_t _M0MPC14uint4UInt8to__byte(uint32_t _M0L4selfS263) {
  int32_t _M0L6_2atmpS709;
  #line 2519 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\intrinsics.mbt"
  _M0L6_2atmpS709 = *(int32_t*)&_M0L4selfS263;
  return _M0L6_2atmpS709 & 0xff;
}

moonbit_string_t _M0MPC13int3Int18to__string_2einner(
  int32_t _M0L4selfS247,
  int32_t _M0L5radixS246
) {
  int32_t _if__result_978;
  int32_t _M0L12is__negativeS248;
  uint32_t _M0L3numS249;
  uint16_t* _M0L6bufferS250;
  #line 209 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
  if (_M0L5radixS246 < 2) {
    _if__result_978 = 1;
  } else {
    _if__result_978 = _M0L5radixS246 > 36;
  }
  if (_if__result_978) {
    #line 213 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
    _M0FPC15abort5abortGuE((moonbit_string_t)moonbit_string_literal_9.data);
  }
  if (_M0L4selfS247 == 0) {
    return (moonbit_string_t)moonbit_string_literal_10.data;
  }
  _M0L12is__negativeS248 = _M0L4selfS247 < 0;
  if (_M0L12is__negativeS248) {
    int32_t _M0L6_2atmpS708 = -_M0L4selfS247;
    _M0L3numS249 = *(uint32_t*)&_M0L6_2atmpS708;
  } else {
    _M0L3numS249 = *(uint32_t*)&_M0L4selfS247;
  }
  switch (_M0L5radixS246) {
    case 10: {
      int32_t _M0L10digit__lenS251;
      int32_t _M0L6_2atmpS705;
      int32_t _M0L10total__lenS252;
      uint16_t* _M0L6bufferS253;
      int32_t _M0L12digit__startS254;
      #line 235 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
      _M0L10digit__lenS251 = _M0FPB12dec__count32(_M0L3numS249);
      if (_M0L12is__negativeS248) {
        _M0L6_2atmpS705 = 1;
      } else {
        _M0L6_2atmpS705 = 0;
      }
      _M0L10total__lenS252 = _M0L10digit__lenS251 + _M0L6_2atmpS705;
      _M0L6bufferS253
      = (uint16_t*)moonbit_make_string(_M0L10total__lenS252, 0);
      if (_M0L12is__negativeS248) {
        _M0L12digit__startS254 = 1;
      } else {
        _M0L12digit__startS254 = 0;
      }
      #line 239 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
      _M0FPB20int__to__string__dec(_M0L6bufferS253, _M0L3numS249, _M0L12digit__startS254, _M0L10total__lenS252);
      _M0L6bufferS250 = _M0L6bufferS253;
      break;
    }
    
    case 16: {
      int32_t _M0L10digit__lenS255;
      int32_t _M0L6_2atmpS706;
      int32_t _M0L10total__lenS256;
      uint16_t* _M0L6bufferS257;
      int32_t _M0L12digit__startS258;
      #line 243 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
      _M0L10digit__lenS255 = _M0FPB12hex__count32(_M0L3numS249);
      if (_M0L12is__negativeS248) {
        _M0L6_2atmpS706 = 1;
      } else {
        _M0L6_2atmpS706 = 0;
      }
      _M0L10total__lenS256 = _M0L10digit__lenS255 + _M0L6_2atmpS706;
      _M0L6bufferS257
      = (uint16_t*)moonbit_make_string(_M0L10total__lenS256, 0);
      if (_M0L12is__negativeS248) {
        _M0L12digit__startS258 = 1;
      } else {
        _M0L12digit__startS258 = 0;
      }
      #line 247 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
      _M0FPB20int__to__string__hex(_M0L6bufferS257, _M0L3numS249, _M0L12digit__startS258, _M0L10total__lenS256);
      _M0L6bufferS250 = _M0L6bufferS257;
      break;
    }
    default: {
      int32_t _M0L10digit__lenS259;
      int32_t _M0L6_2atmpS707;
      int32_t _M0L10total__lenS260;
      uint16_t* _M0L6bufferS261;
      int32_t _M0L12digit__startS262;
      #line 251 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
      _M0L10digit__lenS259
      = _M0FPB14radix__count32(_M0L3numS249, _M0L5radixS246);
      if (_M0L12is__negativeS248) {
        _M0L6_2atmpS707 = 1;
      } else {
        _M0L6_2atmpS707 = 0;
      }
      _M0L10total__lenS260 = _M0L10digit__lenS259 + _M0L6_2atmpS707;
      _M0L6bufferS261
      = (uint16_t*)moonbit_make_string(_M0L10total__lenS260, 0);
      if (_M0L12is__negativeS248) {
        _M0L12digit__startS262 = 1;
      } else {
        _M0L12digit__startS262 = 0;
      }
      #line 255 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
      _M0FPB24int__to__string__generic(_M0L6bufferS261, _M0L3numS249, _M0L12digit__startS262, _M0L10total__lenS260, _M0L5radixS246);
      _M0L6bufferS250 = _M0L6bufferS261;
      break;
    }
  }
  if (_M0L12is__negativeS248) {
    _M0L6bufferS250[0] = 45;
  }
  return _M0L6bufferS250;
}

int32_t _M0FPB14radix__count32(
  uint32_t _M0L5valueS240,
  int32_t _M0L5radixS242
) {
  uint32_t _M0L4baseS241;
  uint32_t _M0L3numS243;
  int32_t _M0L5countS244;
  #line 189 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
  if (_M0L5valueS240 == 0u) {
    return 1;
  }
  _M0L4baseS241 = *(uint32_t*)&_M0L5radixS242;
  _M0L3numS243 = _M0L5valueS240;
  _M0L5countS244 = 0;
  while (1) {
    if (_M0L3numS243 > 0u) {
      uint32_t _M0L6_2atmpS703 = _M0L3numS243 / _M0L4baseS241;
      int32_t _M0L6_2atmpS704 = _M0L5countS244 + 1;
      _M0L3numS243 = _M0L6_2atmpS703;
      _M0L5countS244 = _M0L6_2atmpS704;
      continue;
    } else {
      return _M0L5countS244;
    }
    break;
  }
}

int32_t _M0FPB12hex__count32(uint32_t _M0L5valueS238) {
  #line 177 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
  if (_M0L5valueS238 == 0u) {
    return 1;
  } else {
    int32_t _M0L14leading__zerosS239;
    int32_t _M0L6_2atmpS702;
    int32_t _M0L6_2atmpS701;
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
    _M0L14leading__zerosS239 = moonbit_clz32(_M0L5valueS238);
    _M0L6_2atmpS702 = 31 - _M0L14leading__zerosS239;
    _M0L6_2atmpS701 = _M0L6_2atmpS702 / 4;
    return _M0L6_2atmpS701 + 1;
  }
}

int32_t _M0FPB12dec__count32(uint32_t _M0L5valueS237) {
  #line 143 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
  if (_M0L5valueS237 >= 100000u) {
    if (_M0L5valueS237 >= 10000000u) {
      if (_M0L5valueS237 >= 1000000000u) {
        return 10;
      } else if (_M0L5valueS237 >= 100000000u) {
        return 9;
      } else {
        return 8;
      }
    } else if (_M0L5valueS237 >= 1000000u) {
      return 7;
    } else {
      return 6;
    }
  } else if (_M0L5valueS237 >= 1000u) {
    if (_M0L5valueS237 >= 10000u) {
      return 5;
    } else {
      return 4;
    }
  } else if (_M0L5valueS237 >= 100u) {
    return 3;
  } else if (_M0L5valueS237 >= 10u) {
    return 2;
  } else {
    return 1;
  }
}

int32_t _M0FPB20int__to__string__dec(
  uint16_t* _M0L6bufferS223,
  uint32_t _M0L3numS235,
  int32_t _M0L12digit__startS224,
  int32_t _M0L10total__lenS236
) {
  int32_t _M0L6_2atmpS700;
  uint32_t _M0L3numS213;
  int32_t _M0L6offsetS214;
  #line 88 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
  _M0L6_2atmpS700 = _M0L10total__lenS236 - _M0L12digit__startS224;
  _M0L3numS213 = _M0L3numS235;
  _M0L6offsetS214 = _M0L6_2atmpS700;
  while (1) {
    if (_M0L3numS213 >= 10000u) {
      uint32_t _M0L1tS215 = _M0L3numS213 / 10000u;
      uint32_t _M0L6_2atmpS677 = _M0L3numS213 % 10000u;
      int32_t _M0L1rS216 = *(int32_t*)&_M0L6_2atmpS677;
      int32_t _M0L2d1S217 = _M0L1rS216 / 100;
      int32_t _M0L2d2S218 = _M0L1rS216 % 100;
      int32_t _M0L6_2atmpS676 = _M0L2d1S217 / 10;
      int32_t _M0L6_2atmpS675 = 48 + _M0L6_2atmpS676;
      int32_t _M0L6d1__hiS219 = (uint16_t)_M0L6_2atmpS675;
      int32_t _M0L6_2atmpS674 = _M0L2d1S217 % 10;
      int32_t _M0L6_2atmpS673 = 48 + _M0L6_2atmpS674;
      int32_t _M0L6d1__loS220 = (uint16_t)_M0L6_2atmpS673;
      int32_t _M0L6_2atmpS672 = _M0L2d2S218 / 10;
      int32_t _M0L6_2atmpS671 = 48 + _M0L6_2atmpS672;
      int32_t _M0L6d2__hiS221 = (uint16_t)_M0L6_2atmpS671;
      int32_t _M0L6_2atmpS670 = _M0L2d2S218 % 10;
      int32_t _M0L6_2atmpS669 = 48 + _M0L6_2atmpS670;
      int32_t _M0L6d2__loS222 = (uint16_t)_M0L6_2atmpS669;
      int32_t _M0L6_2atmpS661 = _M0L12digit__startS224 + _M0L6offsetS214;
      int32_t _M0L6_2atmpS660 = _M0L6_2atmpS661 - 4;
      int32_t _M0L6_2atmpS663;
      int32_t _M0L6_2atmpS662;
      int32_t _M0L6_2atmpS665;
      int32_t _M0L6_2atmpS664;
      int32_t _M0L6_2atmpS667;
      int32_t _M0L6_2atmpS666;
      int32_t _M0L6_2atmpS668;
      _M0L6bufferS223[_M0L6_2atmpS660] = _M0L6d1__hiS219;
      _M0L6_2atmpS663 = _M0L12digit__startS224 + _M0L6offsetS214;
      _M0L6_2atmpS662 = _M0L6_2atmpS663 - 3;
      _M0L6bufferS223[_M0L6_2atmpS662] = _M0L6d1__loS220;
      _M0L6_2atmpS665 = _M0L12digit__startS224 + _M0L6offsetS214;
      _M0L6_2atmpS664 = _M0L6_2atmpS665 - 2;
      _M0L6bufferS223[_M0L6_2atmpS664] = _M0L6d2__hiS221;
      _M0L6_2atmpS667 = _M0L12digit__startS224 + _M0L6offsetS214;
      _M0L6_2atmpS666 = _M0L6_2atmpS667 - 1;
      _M0L6bufferS223[_M0L6_2atmpS666] = _M0L6d2__loS222;
      _M0L6_2atmpS668 = _M0L6offsetS214 - 4;
      _M0L3numS213 = _M0L1tS215;
      _M0L6offsetS214 = _M0L6_2atmpS668;
      continue;
    } else {
      int32_t _M0L6_2atmpS699 = *(int32_t*)&_M0L3numS213;
      int32_t _M0L9remainingS226 = _M0L6_2atmpS699;
      int32_t _M0L6offsetS227 = _M0L6offsetS214;
      while (1) {
        if (_M0L9remainingS226 >= 100) {
          int32_t _M0L1tS228 = _M0L9remainingS226 / 100;
          int32_t _M0L1dS229 = _M0L9remainingS226 % 100;
          int32_t _M0L6_2atmpS686 = _M0L1dS229 / 10;
          int32_t _M0L6_2atmpS685 = 48 + _M0L6_2atmpS686;
          int32_t _M0L5d__hiS230 = (uint16_t)_M0L6_2atmpS685;
          int32_t _M0L6_2atmpS684 = _M0L1dS229 % 10;
          int32_t _M0L6_2atmpS683 = 48 + _M0L6_2atmpS684;
          int32_t _M0L5d__loS231 = (uint16_t)_M0L6_2atmpS683;
          int32_t _M0L6_2atmpS679 = _M0L12digit__startS224 + _M0L6offsetS227;
          int32_t _M0L6_2atmpS678 = _M0L6_2atmpS679 - 2;
          int32_t _M0L6_2atmpS681;
          int32_t _M0L6_2atmpS680;
          int32_t _M0L6_2atmpS682;
          _M0L6bufferS223[_M0L6_2atmpS678] = _M0L5d__hiS230;
          _M0L6_2atmpS681 = _M0L12digit__startS224 + _M0L6offsetS227;
          _M0L6_2atmpS680 = _M0L6_2atmpS681 - 1;
          _M0L6bufferS223[_M0L6_2atmpS680] = _M0L5d__loS231;
          _M0L6_2atmpS682 = _M0L6offsetS227 - 2;
          _M0L9remainingS226 = _M0L1tS228;
          _M0L6offsetS227 = _M0L6_2atmpS682;
          continue;
        } else if (_M0L9remainingS226 >= 10) {
          int32_t _M0L6_2atmpS694 = _M0L9remainingS226 / 10;
          int32_t _M0L6_2atmpS693 = 48 + _M0L6_2atmpS694;
          int32_t _M0L5d__hiS233 = (uint16_t)_M0L6_2atmpS693;
          int32_t _M0L6_2atmpS692 = _M0L9remainingS226 % 10;
          int32_t _M0L6_2atmpS691 = 48 + _M0L6_2atmpS692;
          int32_t _M0L5d__loS234 = (uint16_t)_M0L6_2atmpS691;
          int32_t _M0L6_2atmpS688 = _M0L12digit__startS224 + _M0L6offsetS227;
          int32_t _M0L6_2atmpS687 = _M0L6_2atmpS688 - 2;
          int32_t _M0L6_2atmpS690;
          int32_t _M0L6_2atmpS689;
          _M0L6bufferS223[_M0L6_2atmpS687] = _M0L5d__hiS233;
          _M0L6_2atmpS690 = _M0L12digit__startS224 + _M0L6offsetS227;
          _M0L6_2atmpS689 = _M0L6_2atmpS690 - 1;
          _M0L6bufferS223[_M0L6_2atmpS689] = _M0L5d__loS234;
        } else {
          int32_t _M0L6_2atmpS698 = _M0L12digit__startS224 + _M0L6offsetS227;
          int32_t _M0L6_2atmpS695 = _M0L6_2atmpS698 - 1;
          int32_t _M0L6_2atmpS697 = 48 + _M0L9remainingS226;
          int32_t _M0L6_2atmpS696 = (uint16_t)_M0L6_2atmpS697;
          _M0L6bufferS223[_M0L6_2atmpS695] = _M0L6_2atmpS696;
        }
        break;
      }
    }
    break;
  }
  return 0;
}

int32_t _M0FPB24int__to__string__generic(
  uint16_t* _M0L6bufferS203,
  uint32_t _M0L3numS207,
  int32_t _M0L12digit__startS204,
  int32_t _M0L10total__lenS206,
  int32_t _M0L5radixS197
) {
  uint32_t _M0L4baseS196;
  int32_t _M0L6_2atmpS645;
  int32_t _M0L6_2atmpS644;
  #line 57 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
  _M0L4baseS196 = *(uint32_t*)&_M0L5radixS197;
  _M0L6_2atmpS645 = _M0L5radixS197 - 1;
  _M0L6_2atmpS644 = _M0L5radixS197 & _M0L6_2atmpS645;
  if (_M0L6_2atmpS644 == 0) {
    int32_t _M0L5shiftS198;
    uint32_t _M0L4maskS199;
    int32_t _M0L6_2atmpS652;
    int32_t _M0L6offsetS200;
    uint32_t _M0L1nS201;
    #line 68 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
    _M0L5shiftS198 = moonbit_ctz32(_M0L5radixS197);
    _M0L4maskS199 = _M0L4baseS196 - 1u;
    _M0L6_2atmpS652 = _M0L10total__lenS206 - _M0L12digit__startS204;
    _M0L6offsetS200 = _M0L6_2atmpS652;
    _M0L1nS201 = _M0L3numS207;
    while (1) {
      if (_M0L1nS201 > 0u) {
        uint32_t _M0L6_2atmpS651 = _M0L1nS201 & _M0L4maskS199;
        int32_t _M0L5digitS202 = *(int32_t*)&_M0L6_2atmpS651;
        int32_t _M0L6_2atmpS648 = _M0L12digit__startS204 + _M0L6offsetS200;
        int32_t _M0L6_2atmpS646 = _M0L6_2atmpS648 - 1;
        int32_t _M0L6_2atmpS647 =
          ((moonbit_string_t)moonbit_string_literal_11.data)[_M0L5digitS202];
        int32_t _M0L6_2atmpS649;
        uint32_t _M0L6_2atmpS650;
        _M0L6bufferS203[_M0L6_2atmpS646] = _M0L6_2atmpS647;
        _M0L6_2atmpS649 = _M0L6offsetS200 - 1;
        _M0L6_2atmpS650 = _M0L1nS201 >> (_M0L5shiftS198 & 31);
        _M0L6offsetS200 = _M0L6_2atmpS649;
        _M0L1nS201 = _M0L6_2atmpS650;
        continue;
      }
      break;
    }
  } else {
    int32_t _M0L6_2atmpS659 = _M0L10total__lenS206 - _M0L12digit__startS204;
    int32_t _M0L6offsetS208 = _M0L6_2atmpS659;
    uint32_t _M0L1nS209 = _M0L3numS207;
    while (1) {
      if (_M0L1nS209 > 0u) {
        uint32_t _M0L1qS210 = _M0L1nS209 / _M0L4baseS196;
        uint32_t _M0L6_2atmpS658 = _M0L1qS210 * _M0L4baseS196;
        uint32_t _M0L6_2atmpS657 = _M0L1nS209 - _M0L6_2atmpS658;
        int32_t _M0L5digitS211 = *(int32_t*)&_M0L6_2atmpS657;
        int32_t _M0L6_2atmpS655 = _M0L12digit__startS204 + _M0L6offsetS208;
        int32_t _M0L6_2atmpS653 = _M0L6_2atmpS655 - 1;
        int32_t _M0L6_2atmpS654 =
          ((moonbit_string_t)moonbit_string_literal_11.data)[_M0L5digitS211];
        int32_t _M0L6_2atmpS656;
        _M0L6bufferS203[_M0L6_2atmpS653] = _M0L6_2atmpS654;
        _M0L6_2atmpS656 = _M0L6offsetS208 - 1;
        _M0L6offsetS208 = _M0L6_2atmpS656;
        _M0L1nS209 = _M0L1qS210;
        continue;
      }
      break;
    }
  }
  return 0;
}

int32_t _M0FPB20int__to__string__hex(
  uint16_t* _M0L6bufferS190,
  uint32_t _M0L3numS195,
  int32_t _M0L12digit__startS191,
  int32_t _M0L10total__lenS194
) {
  int32_t _M0L6_2atmpS643;
  int32_t _M0L6offsetS185;
  uint32_t _M0L1nS186;
  #line 29 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\to_string.mbt"
  _M0L6_2atmpS643 = _M0L10total__lenS194 - _M0L12digit__startS191;
  _M0L6offsetS185 = _M0L6_2atmpS643;
  _M0L1nS186 = _M0L3numS195;
  while (1) {
    if (_M0L6offsetS185 >= 2) {
      uint32_t _M0L6_2atmpS640 = _M0L1nS186 & 255u;
      int32_t _M0L9byte__valS187 = *(int32_t*)&_M0L6_2atmpS640;
      int32_t _M0L2hiS188 = _M0L9byte__valS187 / 16;
      int32_t _M0L2loS189 = _M0L9byte__valS187 % 16;
      int32_t _M0L6_2atmpS634 = _M0L12digit__startS191 + _M0L6offsetS185;
      int32_t _M0L6_2atmpS632 = _M0L6_2atmpS634 - 2;
      int32_t _M0L6_2atmpS633 =
        ((moonbit_string_t)moonbit_string_literal_11.data)[_M0L2hiS188];
      int32_t _M0L6_2atmpS637;
      int32_t _M0L6_2atmpS635;
      int32_t _M0L6_2atmpS636;
      int32_t _M0L6_2atmpS638;
      uint32_t _M0L6_2atmpS639;
      _M0L6bufferS190[_M0L6_2atmpS632] = _M0L6_2atmpS633;
      _M0L6_2atmpS637 = _M0L12digit__startS191 + _M0L6offsetS185;
      _M0L6_2atmpS635 = _M0L6_2atmpS637 - 1;
      _M0L6_2atmpS636
      = ((moonbit_string_t)moonbit_string_literal_11.data)[
        _M0L2loS189
      ];
      _M0L6bufferS190[_M0L6_2atmpS635] = _M0L6_2atmpS636;
      _M0L6_2atmpS638 = _M0L6offsetS185 - 2;
      _M0L6_2atmpS639 = _M0L1nS186 >> 8;
      _M0L6offsetS185 = _M0L6_2atmpS638;
      _M0L1nS186 = _M0L6_2atmpS639;
      continue;
    } else if (_M0L6offsetS185 == 1) {
      uint32_t _M0L6_2atmpS642 = _M0L1nS186 & 15u;
      int32_t _M0L6nibbleS193 = *(int32_t*)&_M0L6_2atmpS642;
      int32_t _M0L6_2atmpS641 =
        ((moonbit_string_t)moonbit_string_literal_11.data)[_M0L6nibbleS193];
      _M0L6bufferS190[_M0L12digit__startS191] = _M0L6_2atmpS641;
    }
    break;
  }
  return 0;
}

moonbit_string_t _M0IP016_24default__implPB4Show10to__stringGRPB7FailureE(
  void* _M0L4selfS184
) {
  struct _M0TPB13StringBuilder* _M0L6loggerS183;
  struct _M0TPB6Logger _M0L6_2atmpS631;
  moonbit_string_t _result_985;
  #line 165 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  #line 166 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L6loggerS183 = _M0MPB13StringBuilder21StringBuilder_2einner(0);
  moonbit_incref(_M0L6loggerS183);
  _M0L6_2atmpS631
  = (struct _M0TPB6Logger){
    _M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id,
      _M0L6loggerS183
  };
  #line 167 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0IPB7FailurePB4Show6output(_M0L4selfS184, _M0L6_2atmpS631);
  if (_M0L6_2atmpS631.$1) {
    moonbit_decref(_M0L6_2atmpS631.$1);
  }
  #line 168 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _result_985 = _M0MPB13StringBuilder10to__string(_M0L6loggerS183);
  moonbit_decref(_M0L6loggerS183);
  return _result_985;
}

int32_t _M0IP016_24default__implPB4Show6outputGsE(
  moonbit_string_t _M0L4selfS180,
  struct _M0TPB6Logger _M0L6loggerS179
) {
  moonbit_string_t _M0L6_2atmpS629;
  #line 159 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  #line 160 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L6_2atmpS629 = _M0IPC16string6StringPB4Show10to__string(_M0L4selfS180);
  #line 160 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L6loggerS179.$0->$method_0(_M0L6loggerS179.$1, _M0L6_2atmpS629);
  moonbit_decref(_M0L6_2atmpS629);
  return 0;
}

int32_t _M0IP016_24default__implPB4Show6outputGiE(
  int32_t _M0L4selfS182,
  struct _M0TPB6Logger _M0L6loggerS181
) {
  moonbit_string_t _M0L6_2atmpS630;
  #line 159 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  #line 160 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L6_2atmpS630 = _M0IPC13int3IntPB4Show10to__string(_M0L4selfS182);
  #line 160 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L6loggerS181.$0->$method_0(_M0L6loggerS181.$1, _M0L6_2atmpS630);
  moonbit_decref(_M0L6_2atmpS630);
  return 0;
}

int32_t _M0MPC16string10StringView13start__offset(
  struct _M0TPC16string10StringView _M0L4selfS178
) {
  #line 99 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
  return _M0L4selfS178.$1;
}

moonbit_string_t _M0MPC16string10StringView4data(
  struct _M0TPC16string10StringView _M0L4selfS177
) {
  moonbit_string_t _M0L8_2afieldS911;
  #line 92 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
  _M0L8_2afieldS911 = _M0L4selfS177.$0;
  moonbit_incref(_M0L8_2afieldS911);
  return _M0L8_2afieldS911;
}

int32_t _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(
  struct _M0TPB13StringBuilder* _M0L4selfS173,
  moonbit_string_t _M0L5valueS174,
  int32_t _M0L5startS175,
  int32_t _M0L3lenS176
) {
  int32_t _M0L6_2atmpS628;
  int64_t _M0L6_2atmpS627;
  struct _M0TPC16string10StringView _M0L6_2atmpS626;
  #line 122 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L6_2atmpS628 = _M0L5startS175 + _M0L3lenS176;
  _M0L6_2atmpS627 = (int64_t)_M0L6_2atmpS628;
  #line 123 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L6_2atmpS626
  = _M0MPC16string6String11sub_2einner(_M0L5valueS174, _M0L5startS175, _M0L6_2atmpS627);
  #line 123 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0IPB13StringBuilderPB6Logger11write__view(_M0L4selfS173, _M0L6_2atmpS626);
  moonbit_decref(_M0L6_2atmpS626.$0);
  return 0;
}

struct _M0TPC16string10StringView _M0MPC16string6String11sub_2einner(
  moonbit_string_t _M0L4selfS168,
  int32_t _M0L5startS172,
  int64_t _M0L3endS170
) {
  int32_t _M0L3lenS167;
  int32_t _M0L3endS169;
  int32_t _if__result_986;
  #line 754 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
  _M0L3lenS167 = Moonbit_array_length(_M0L4selfS168);
  if (_M0L3endS170 == 4294967296ll) {
    _M0L3endS169 = _M0L3lenS167;
  } else {
    int64_t _M0L7_2aSomeS171 = _M0L3endS170;
    _M0L3endS169 = (int32_t)_M0L7_2aSomeS171;
  }
  if (_M0L5startS172 >= 0) {
    if (_M0L5startS172 <= _M0L3endS169) {
      _if__result_986 = _M0L3endS169 <= _M0L3lenS167;
    } else {
      _if__result_986 = 0;
    }
  } else {
    _if__result_986 = 0;
  }
  if (_if__result_986) {
    if (_M0L5startS172 < _M0L3lenS167) {
      int32_t _M0L6_2atmpS623 = _M0L4selfS168[_M0L5startS172];
      int32_t _M0L6_2atmpS622;
      #line 763 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
      _M0L6_2atmpS622
      = _M0MPC16uint166UInt1623is__trailing__surrogate(_M0L6_2atmpS623);
      if (!_M0L6_2atmpS622) {
        
      } else {
        #line 763 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
        moonbit_panic();
      }
    }
    if (_M0L3endS169 < _M0L3lenS167) {
      int32_t _M0L6_2atmpS625 = _M0L4selfS168[_M0L3endS169];
      int32_t _M0L6_2atmpS624;
      #line 766 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
      _M0L6_2atmpS624
      = _M0MPC16uint166UInt1623is__trailing__surrogate(_M0L6_2atmpS625);
      if (!_M0L6_2atmpS624) {
        
      } else {
        #line 766 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
        moonbit_panic();
      }
    }
    moonbit_incref(_M0L4selfS168);
    return (struct _M0TPC16string10StringView){.$0 = _M0L4selfS168,
                                                 .$1 = _M0L5startS172,
                                                 .$2 = _M0L3endS169};
  } else {
    #line 761 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
    moonbit_panic();
  }
}

int32_t _M0IP016_24default__implPB6Logger5writeGRPB13StringBuilderE(
  struct _M0TPB13StringBuilder* _M0L4selfS166,
  struct _M0TPB4Show _M0L4showS165
) {
  struct _M0TPB6Logger _M0L6_2atmpS621;
  #line 116 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  moonbit_incref(_M0L4selfS166);
  _M0L6_2atmpS621
  = (struct _M0TPB6Logger){
    _M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id,
      _M0L4selfS166
  };
  #line 117 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L4showS165.$0->$method_0(_M0L4showS165.$1, _M0L6_2atmpS621);
  if (_M0L6_2atmpS621.$1) {
    moonbit_decref(_M0L6_2atmpS621.$1);
  }
  return 0;
}

int32_t _M0IP016_24default__implPB6Logger28write__string__interpolationGRPB13StringBuilderE(
  struct _M0TPB13StringBuilder* _M0L4selfS164,
  struct _M0TPB4Show _M0L4showS163
) {
  struct _M0TPB6Logger _M0L6_2atmpS620;
  #line 111 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  moonbit_incref(_M0L4selfS164);
  _M0L6_2atmpS620
  = (struct _M0TPB6Logger){
    _M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id,
      _M0L4selfS164
  };
  #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0L4showS163.$0->$method_0(_M0L4showS163.$1, _M0L6_2atmpS620);
  if (_M0L6_2atmpS620.$1) {
    moonbit_decref(_M0L6_2atmpS620.$1);
  }
  return 0;
}

int32_t _M0IPB13StringBuilderPB6Logger13write__string(
  struct _M0TPB13StringBuilder* _M0L4selfS162,
  moonbit_string_t _M0L3strS161
) {
  int32_t _M0L8str__lenS160;
  int32_t _M0L3lenS615;
  int32_t _M0L6_2atmpS614;
  uint16_t* _M0L4dataS616;
  int32_t _M0L3lenS617;
  int32_t _M0L3lenS619;
  int32_t _M0L6_2atmpS618;
  #line 86 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L8str__lenS160 = Moonbit_array_length(_M0L3strS161);
  if (_M0L8str__lenS160 == 0) {
    return 0;
  }
  _M0L3lenS615 = _M0L4selfS162->$1;
  _M0L6_2atmpS614 = _M0L3lenS615 + _M0L8str__lenS160;
  #line 91 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0MPB13StringBuilder19grow__if__necessary(_M0L4selfS162, _M0L6_2atmpS614);
  _M0L4dataS616 = _M0L4selfS162->$0;
  _M0L3lenS617 = _M0L4selfS162->$1;
  moonbit_incref(_M0L4dataS616);
  #line 92 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0MPC15array10FixedArray26unsafe__blit__from__string(_M0L4dataS616, _M0L3lenS617, _M0L3strS161, 0, _M0L8str__lenS160);
  moonbit_decref(_M0L4dataS616);
  _M0L3lenS619 = _M0L4selfS162->$1;
  _M0L6_2atmpS618 = _M0L3lenS619 + _M0L8str__lenS160;
  _M0L4selfS162->$1 = _M0L6_2atmpS618;
  return 0;
}

int32_t _M0MPC15array10FixedArray26unsafe__blit__from__string(
  uint16_t* _M0L4selfS156,
  int32_t _M0L11dst__offsetS159,
  moonbit_string_t _M0L3strS157,
  int32_t _M0L11str__offsetS152,
  int32_t _M0L3lenS153
) {
  int32_t _M0L16end__str__offsetS151;
  int32_t _M0L1iS154;
  int32_t _M0L1jS155;
  #line 71 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L16end__str__offsetS151 = _M0L11str__offsetS152 + _M0L3lenS153;
  _M0L1iS154 = _M0L11str__offsetS152;
  _M0L1jS155 = _M0L11dst__offsetS159;
  while (1) {
    if (_M0L1iS154 < _M0L16end__str__offsetS151) {
      int32_t _M0L6_2atmpS611 = _M0L3strS157[_M0L1iS154];
      int32_t _M0L6_2atmpS612;
      int32_t _M0L6_2atmpS613;
      _M0L4selfS156[_M0L1jS155] = _M0L6_2atmpS611;
      _M0L6_2atmpS612 = _M0L1iS154 + 1;
      _M0L6_2atmpS613 = _M0L1jS155 + 1;
      _M0L1iS154 = _M0L6_2atmpS612;
      _M0L1jS155 = _M0L6_2atmpS613;
      continue;
    }
    break;
  }
  return 0;
}

moonbit_string_t _M0MPC16string6String14escape_2einner(
  moonbit_string_t _M0L4selfS149,
  int32_t _M0L5quoteS150
) {
  struct _M0TPB13StringBuilder* _M0L3bufS148;
  int32_t _M0L6_2atmpS610;
  struct _M0TPC16string10StringView _M0L6_2atmpS608;
  struct _M0TPB6Logger _M0L6_2atmpS609;
  moonbit_string_t _result_988;
  #line 110 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  #line 111 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0L3bufS148 = _M0MPB13StringBuilder21StringBuilder_2einner(0);
  _M0L6_2atmpS610 = Moonbit_array_length(_M0L4selfS149);
  moonbit_incref(_M0L4selfS149);
  _M0L6_2atmpS608
  = (struct _M0TPC16string10StringView){
    .$0 = _M0L4selfS149, .$1 = 0, .$2 = _M0L6_2atmpS610
  };
  moonbit_incref(_M0L3bufS148);
  _M0L6_2atmpS609
  = (struct _M0TPB6Logger){
    _M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id,
      _M0L3bufS148
  };
  #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0MPC16string10StringView18escape__to_2einner(_M0L6_2atmpS608, _M0L6_2atmpS609, _M0L5quoteS150);
  moonbit_decref(_M0L6_2atmpS608.$0);
  if (_M0L6_2atmpS609.$1) {
    moonbit_decref(_M0L6_2atmpS609.$1);
  }
  #line 113 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _result_988 = _M0MPB13StringBuilder10to__string(_M0L3bufS148);
  moonbit_decref(_M0L3bufS148);
  return _result_988;
}

int32_t _M0MPC16string10StringView18escape__to_2einner(
  struct _M0TPC16string10StringView _M0L4selfS140,
  struct _M0TPB6Logger _M0L6loggerS138,
  int32_t _M0L5quoteS137
) {
  int32_t _M0L3endS606;
  int32_t _M0L5startS607;
  int32_t _M0L3lenS139;
  struct _M0TURPB6LoggerRPC16string10StringViewE* _M0L6_2aenvS141;
  int32_t _M0L1iS142;
  int32_t _M0L3segS143;
  #line 144 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  if (_M0L5quoteS137) {
    #line 150 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6loggerS138.$0->$method_3(_M0L6loggerS138.$1, 34);
  }
  _M0L3endS606 = _M0L4selfS140.$2;
  _M0L5startS607 = _M0L4selfS140.$1;
  _M0L3lenS139 = _M0L3endS606 - _M0L5startS607;
  if (_M0L6loggerS138.$1) {
    moonbit_incref(_M0L6loggerS138.$1);
  }
  moonbit_incref(_M0L4selfS140.$0);
  _M0L6_2aenvS141
  = (struct _M0TURPB6LoggerRPC16string10StringViewE*)moonbit_malloc(sizeof(struct _M0TURPB6LoggerRPC16string10StringViewE));
  Moonbit_object_header(_M0L6_2aenvS141)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 25, 0);
  _M0L6_2aenvS141->$0 = _M0L6loggerS138;
  _M0L6_2aenvS141->$1 = _M0L4selfS140;
  _M0L1iS142 = 0;
  _M0L3segS143 = 0;
  _2afor_144:;
  while (1) {
    moonbit_string_t _M0L3strS603;
    int32_t _M0L5startS605;
    int32_t _M0L6_2atmpS604;
    int32_t _M0L4codeS145;
    int32_t _M0L1cS147;
    int32_t _M0L6_2atmpS587;
    int32_t _M0L6_2atmpS588;
    int32_t _M0L6_2atmpS589;
    int32_t _tmp_992;
    int32_t _tmp_993;
    if (_M0L1iS142 >= _M0L3lenS139) {
      #line 160 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
      _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(_M0L6_2aenvS141, _M0L3segS143, _M0L1iS142);
      moonbit_decref(_M0L6_2aenvS141);
      break;
    }
    _M0L3strS603 = _M0L4selfS140.$0;
    _M0L5startS605 = _M0L4selfS140.$1;
    _M0L6_2atmpS604 = _M0L5startS605 + _M0L1iS142;
    _M0L4codeS145 = _M0L3strS603[_M0L6_2atmpS604];
    switch (_M0L4codeS145) {
      case 34: {
        _M0L1cS147 = _M0L4codeS145;
        goto join_146;
        break;
      }
      
      case 92: {
        _M0L1cS147 = _M0L4codeS145;
        goto join_146;
        break;
      }
      
      case 10: {
        int32_t _M0L6_2atmpS590;
        int32_t _M0L6_2atmpS591;
        #line 172 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
        _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(_M0L6_2aenvS141, _M0L3segS143, _M0L1iS142);
        #line 173 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
        _M0L6loggerS138.$0->$method_0(_M0L6loggerS138.$1, (moonbit_string_t)moonbit_string_literal_12.data);
        _M0L6_2atmpS590 = _M0L1iS142 + 1;
        _M0L6_2atmpS591 = _M0L1iS142 + 1;
        _M0L1iS142 = _M0L6_2atmpS590;
        _M0L3segS143 = _M0L6_2atmpS591;
        goto _2afor_144;
        break;
      }
      
      case 13: {
        int32_t _M0L6_2atmpS592;
        int32_t _M0L6_2atmpS593;
        #line 177 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
        _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(_M0L6_2aenvS141, _M0L3segS143, _M0L1iS142);
        #line 178 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
        _M0L6loggerS138.$0->$method_0(_M0L6loggerS138.$1, (moonbit_string_t)moonbit_string_literal_13.data);
        _M0L6_2atmpS592 = _M0L1iS142 + 1;
        _M0L6_2atmpS593 = _M0L1iS142 + 1;
        _M0L1iS142 = _M0L6_2atmpS592;
        _M0L3segS143 = _M0L6_2atmpS593;
        goto _2afor_144;
        break;
      }
      
      case 8: {
        int32_t _M0L6_2atmpS594;
        int32_t _M0L6_2atmpS595;
        #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
        _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(_M0L6_2aenvS141, _M0L3segS143, _M0L1iS142);
        #line 183 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
        _M0L6loggerS138.$0->$method_0(_M0L6loggerS138.$1, (moonbit_string_t)moonbit_string_literal_14.data);
        _M0L6_2atmpS594 = _M0L1iS142 + 1;
        _M0L6_2atmpS595 = _M0L1iS142 + 1;
        _M0L1iS142 = _M0L6_2atmpS594;
        _M0L3segS143 = _M0L6_2atmpS595;
        goto _2afor_144;
        break;
      }
      
      case 9: {
        int32_t _M0L6_2atmpS596;
        int32_t _M0L6_2atmpS597;
        #line 187 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
        _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(_M0L6_2aenvS141, _M0L3segS143, _M0L1iS142);
        #line 188 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
        _M0L6loggerS138.$0->$method_0(_M0L6loggerS138.$1, (moonbit_string_t)moonbit_string_literal_15.data);
        _M0L6_2atmpS596 = _M0L1iS142 + 1;
        _M0L6_2atmpS597 = _M0L1iS142 + 1;
        _M0L1iS142 = _M0L6_2atmpS596;
        _M0L3segS143 = _M0L6_2atmpS597;
        goto _2afor_144;
        break;
      }
      default: {
        if (_M0L4codeS145 < 32) {
          int32_t _M0L6_2atmpS599;
          moonbit_string_t _M0L6_2atmpS598;
          int32_t _M0L6_2atmpS600;
          int32_t _M0L6_2atmpS601;
          #line 193 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
          _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(_M0L6_2aenvS141, _M0L3segS143, _M0L1iS142);
          #line 194 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
          _M0L6loggerS138.$0->$method_0(_M0L6loggerS138.$1, (moonbit_string_t)moonbit_string_literal_16.data);
          _M0L6_2atmpS599 = _M0L4codeS145 & 0xff;
          #line 195 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
          _M0L6_2atmpS598 = _M0MPC14byte4Byte7to__hex(_M0L6_2atmpS599);
          #line 195 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
          _M0L6loggerS138.$0->$method_0(_M0L6loggerS138.$1, _M0L6_2atmpS598);
          moonbit_decref(_M0L6_2atmpS598);
          #line 196 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
          _M0L6loggerS138.$0->$method_3(_M0L6loggerS138.$1, 125);
          _M0L6_2atmpS600 = _M0L1iS142 + 1;
          _M0L6_2atmpS601 = _M0L1iS142 + 1;
          _M0L1iS142 = _M0L6_2atmpS600;
          _M0L3segS143 = _M0L6_2atmpS601;
          goto _2afor_144;
        } else {
          int32_t _M0L6_2atmpS602 = _M0L1iS142 + 1;
          int32_t _tmp_991 = _M0L3segS143;
          _M0L1iS142 = _M0L6_2atmpS602;
          _M0L3segS143 = _tmp_991;
          goto _2afor_144;
        }
        break;
      }
    }
    goto joinlet_990;
    join_146:;
    #line 166 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(_M0L6_2aenvS141, _M0L3segS143, _M0L1iS142);
    #line 167 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6loggerS138.$0->$method_3(_M0L6loggerS138.$1, 92);
    #line 168 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6_2atmpS587 = _M0MPC16uint166UInt1616unsafe__to__char(_M0L1cS147);
    #line 168 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6loggerS138.$0->$method_3(_M0L6loggerS138.$1, _M0L6_2atmpS587);
    _M0L6_2atmpS588 = _M0L1iS142 + 1;
    _M0L6_2atmpS589 = _M0L1iS142 + 1;
    _M0L1iS142 = _M0L6_2atmpS588;
    _M0L3segS143 = _M0L6_2atmpS589;
    continue;
    joinlet_990:;
    _tmp_992 = _M0L1iS142;
    _tmp_993 = _M0L3segS143;
    _M0L1iS142 = _tmp_992;
    _M0L3segS143 = _tmp_993;
    continue;
    break;
  }
  if (_M0L5quoteS137) {
    #line 204 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6loggerS138.$0->$method_3(_M0L6loggerS138.$1, 34);
  }
  return 0;
}

int32_t _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS4242(
  struct _M0TURPB6LoggerRPC16string10StringViewE* _M0L6_2aenvS133,
  int32_t _M0L3segS136,
  int32_t _M0L1iS135
) {
  struct _M0TPC16string10StringView _M0L4selfS132;
  struct _M0TPB6Logger _M0L6loggerS134;
  #line 153 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0L4selfS132 = _M0L6_2aenvS133->$1;
  _M0L6loggerS134 = _M0L6_2aenvS133->$0;
  if (_M0L1iS135 > _M0L3segS136) {
    int64_t _M0L6_2atmpS586 = (int64_t)_M0L1iS135;
    struct _M0TPC16string10StringView _M0L6_2atmpS585;
    #line 155 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6_2atmpS585
    = _M0MPC16string10StringView11sub_2einner(_M0L4selfS132, _M0L3segS136, _M0L6_2atmpS586);
    #line 155 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6loggerS134.$0->$method_2(_M0L6loggerS134.$1, _M0L6_2atmpS585);
    moonbit_decref(_M0L6_2atmpS585.$0);
  }
  return 0;
}

struct _M0TPC16string10StringView _M0MPC16string10StringView11sub_2einner(
  struct _M0TPC16string10StringView _M0L4selfS125,
  int32_t _M0L5startS131,
  int64_t _M0L3endS127
) {
  moonbit_string_t _M0L3strS584;
  int32_t _M0L8str__lenS124;
  int32_t _M0L8abs__endS126;
  int32_t _M0L5startS582;
  int32_t _M0L10abs__startS130;
  int32_t _M0L5startS574;
  int32_t _if__result_994;
  #line 810 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
  _M0L3strS584 = _M0L4selfS125.$0;
  _M0L8str__lenS124 = Moonbit_array_length(_M0L3strS584);
  if (_M0L3endS127 == 4294967296ll) {
    _M0L8abs__endS126 = _M0L4selfS125.$2;
  } else {
    int64_t _M0L7_2aSomeS128 = _M0L3endS127;
    int32_t _M0L6_2aendS129 = (int32_t)_M0L7_2aSomeS128;
    int32_t _M0L5startS583 = _M0L4selfS125.$1;
    _M0L8abs__endS126 = _M0L5startS583 + _M0L6_2aendS129;
  }
  _M0L5startS582 = _M0L4selfS125.$1;
  _M0L10abs__startS130 = _M0L5startS582 + _M0L5startS131;
  _M0L5startS574 = _M0L4selfS125.$1;
  if (_M0L10abs__startS130 >= _M0L5startS574) {
    if (_M0L10abs__startS130 <= _M0L8abs__endS126) {
      int32_t _M0L3endS573 = _M0L4selfS125.$2;
      _if__result_994 = _M0L8abs__endS126 <= _M0L3endS573;
    } else {
      _if__result_994 = 0;
    }
  } else {
    _if__result_994 = 0;
  }
  if (_if__result_994) {
    moonbit_string_t _M0L3strS581;
    if (_M0L10abs__startS130 < _M0L8str__lenS124) {
      moonbit_string_t _M0L3strS577 = _M0L4selfS125.$0;
      int32_t _M0L6_2atmpS576 = _M0L3strS577[_M0L10abs__startS130];
      int32_t _M0L6_2atmpS575;
      #line 832 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
      _M0L6_2atmpS575
      = _M0MPC16uint166UInt1623is__trailing__surrogate(_M0L6_2atmpS576);
      if (!_M0L6_2atmpS575) {
        
      } else {
        #line 832 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
        moonbit_panic();
      }
    }
    if (_M0L8abs__endS126 < _M0L8str__lenS124) {
      moonbit_string_t _M0L3strS580 = _M0L4selfS125.$0;
      int32_t _M0L6_2atmpS579 = _M0L3strS580[_M0L8abs__endS126];
      int32_t _M0L6_2atmpS578;
      #line 835 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
      _M0L6_2atmpS578
      = _M0MPC16uint166UInt1623is__trailing__surrogate(_M0L6_2atmpS579);
      if (!_M0L6_2atmpS578) {
        
      } else {
        #line 835 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
        moonbit_panic();
      }
    }
    _M0L3strS581 = _M0L4selfS125.$0;
    moonbit_incref(_M0L3strS581);
    return (struct _M0TPC16string10StringView){.$0 = _M0L3strS581,
                                                 .$1 = _M0L10abs__startS130,
                                                 .$2 = _M0L8abs__endS126};
  } else {
    #line 826 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringview.mbt"
    moonbit_panic();
  }
}

moonbit_string_t _M0MPC14byte4Byte7to__hex(int32_t _M0L1bS123) {
  struct _M0TPB13StringBuilder* _M0L7_2aselfS122;
  int32_t _M0L6_2atmpS570;
  int32_t _M0L6_2atmpS569;
  int32_t _M0L6_2atmpS572;
  int32_t _M0L6_2atmpS571;
  struct _M0TPB13StringBuilder* _M0L6_2atmpS568;
  moonbit_string_t _result_995;
  #line 74 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  #line 83 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0L7_2aselfS122 = _M0MPB13StringBuilder21StringBuilder_2einner(0);
  #line 83 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0L6_2atmpS570 = _M0IPC14byte4BytePB3Div3div(_M0L1bS123, 16);
  #line 83 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0L6_2atmpS569
  = _M0MPC14byte4Byte7to__hexN14to__hex__digitS4257(_M0L6_2atmpS570);
  #line 83 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0IPB13StringBuilderPB6Logger11write__char(_M0L7_2aselfS122, _M0L6_2atmpS569);
  #line 83 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0L6_2atmpS572 = _M0IPC14byte4BytePB3Mod3mod(_M0L1bS123, 16);
  #line 83 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0L6_2atmpS571
  = _M0MPC14byte4Byte7to__hexN14to__hex__digitS4257(_M0L6_2atmpS572);
  #line 83 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _M0IPB13StringBuilderPB6Logger11write__char(_M0L7_2aselfS122, _M0L6_2atmpS571);
  _M0L6_2atmpS568 = _M0L7_2aselfS122;
  #line 83 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  _result_995 = _M0MPB13StringBuilder10to__string(_M0L6_2atmpS568);
  moonbit_decref(_M0L6_2atmpS568);
  return _result_995;
}

int32_t _M0MPC14byte4Byte7to__hexN14to__hex__digitS4257(int32_t _M0L1iS121) {
  #line 75 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
  if (_M0L1iS121 < 10) {
    int32_t _M0L6_2atmpS565;
    #line 77 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6_2atmpS565 = _M0IPC14byte4BytePB3Add3add(_M0L1iS121, 48);
    #line 77 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    return _M0MPC14byte4Byte8to__char(_M0L6_2atmpS565);
  } else {
    int32_t _M0L6_2atmpS567;
    int32_t _M0L6_2atmpS566;
    #line 79 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6_2atmpS567 = _M0IPC14byte4BytePB3Add3add(_M0L1iS121, 97);
    #line 79 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    _M0L6_2atmpS566 = _M0IPC14byte4BytePB3Sub3sub(_M0L6_2atmpS567, 10);
    #line 79 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\show.mbt"
    return _M0MPC14byte4Byte8to__char(_M0L6_2atmpS566);
  }
}

int32_t _M0IPC14byte4BytePB3Sub3sub(
  int32_t _M0L4selfS119,
  int32_t _M0L4thatS120
) {
  int32_t _M0L6_2atmpS563;
  int32_t _M0L6_2atmpS564;
  int32_t _M0L6_2atmpS562;
  #line 120 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\byte.mbt"
  _M0L6_2atmpS563 = (int32_t)_M0L4selfS119;
  _M0L6_2atmpS564 = (int32_t)_M0L4thatS120;
  _M0L6_2atmpS562 = _M0L6_2atmpS563 - _M0L6_2atmpS564;
  return _M0L6_2atmpS562 & 0xff;
}

int32_t _M0IPC14byte4BytePB3Mod3mod(
  int32_t _M0L4selfS117,
  int32_t _M0L4thatS118
) {
  int32_t _M0L6_2atmpS560;
  int32_t _M0L6_2atmpS561;
  int32_t _M0L6_2atmpS559;
  #line 67 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\byte.mbt"
  _M0L6_2atmpS560 = (int32_t)_M0L4selfS117;
  _M0L6_2atmpS561 = (int32_t)_M0L4thatS118;
  _M0L6_2atmpS559 = _M0L6_2atmpS560 % _M0L6_2atmpS561;
  return _M0L6_2atmpS559 & 0xff;
}

int32_t _M0IPC14byte4BytePB3Div3div(
  int32_t _M0L4selfS115,
  int32_t _M0L4thatS116
) {
  int32_t _M0L6_2atmpS557;
  int32_t _M0L6_2atmpS558;
  int32_t _M0L6_2atmpS556;
  #line 62 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\byte.mbt"
  _M0L6_2atmpS557 = (int32_t)_M0L4selfS115;
  _M0L6_2atmpS558 = (int32_t)_M0L4thatS116;
  _M0L6_2atmpS556 = _M0L6_2atmpS557 / _M0L6_2atmpS558;
  return _M0L6_2atmpS556 & 0xff;
}

int32_t _M0IPC14byte4BytePB3Add3add(
  int32_t _M0L4selfS113,
  int32_t _M0L4thatS114
) {
  int32_t _M0L6_2atmpS554;
  int32_t _M0L6_2atmpS555;
  int32_t _M0L6_2atmpS553;
  #line 106 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\byte.mbt"
  _M0L6_2atmpS554 = (int32_t)_M0L4selfS113;
  _M0L6_2atmpS555 = (int32_t)_M0L4thatS114;
  _M0L6_2atmpS553 = _M0L6_2atmpS554 + _M0L6_2atmpS555;
  return _M0L6_2atmpS553 & 0xff;
}

int32_t _M0MPC16uint166UInt1616unsafe__to__char(int32_t _M0L4selfS112) {
  int32_t _M0L6_2atmpS552;
  #line 68 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uint16_char.mbt"
  _M0L6_2atmpS552 = (int32_t)_M0L4selfS112;
  return _M0L6_2atmpS552;
}

int32_t _M0MPC16uint166UInt1623is__trailing__surrogate(int32_t _M0L4selfS111) {
  #line 45 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uint16_char.mbt"
  if (_M0L4selfS111 >= 56320) {
    return _M0L4selfS111 <= 57343;
  } else {
    return 0;
  }
}

int32_t _M0IPB13StringBuilderPB6Logger11write__char(
  struct _M0TPB13StringBuilder* _M0L4selfS109,
  int32_t _M0L2chS108
) {
  uint32_t _M0L4codeS107;
  #line 98 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  #line 99 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L4codeS107 = _M0MPC14char4Char8to__uint(_M0L2chS108);
  if (_M0L4codeS107 <= 65535u) {
    int32_t _M0L3lenS531 = _M0L4selfS109->$1;
    int32_t _M0L6_2atmpS530 = _M0L3lenS531 + 1;
    uint16_t* _M0L4dataS532;
    int32_t _M0L3lenS533;
    int32_t _M0L6_2atmpS534;
    int32_t _M0L3lenS536;
    int32_t _M0L6_2atmpS535;
    #line 101 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
    _M0MPB13StringBuilder19grow__if__necessary(_M0L4selfS109, _M0L6_2atmpS530);
    _M0L4dataS532 = _M0L4selfS109->$0;
    _M0L3lenS533 = _M0L4selfS109->$1;
    moonbit_incref(_M0L4dataS532);
    #line 102 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
    _M0L6_2atmpS534 = _M0MPC14uint4UInt10to__uint16(_M0L4codeS107);
    if (
      _M0L3lenS533 < 0 || _M0L3lenS533 >= Moonbit_array_length(_M0L4dataS532)
    ) {
      #line 102 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
      moonbit_panic();
    }
    _M0L4dataS532[_M0L3lenS533] = _M0L6_2atmpS534;
    moonbit_decref(_M0L4dataS532);
    _M0L3lenS536 = _M0L4selfS109->$1;
    _M0L6_2atmpS535 = _M0L3lenS536 + 1;
    _M0L4selfS109->$1 = _M0L6_2atmpS535;
  } else if (_M0L4codeS107 <= 1114111u) {
    int32_t _M0L3lenS538 = _M0L4selfS109->$1;
    int32_t _M0L6_2atmpS537 = _M0L3lenS538 + 2;
    uint32_t _M0L4codeS110;
    uint16_t* _M0L4dataS539;
    int32_t _M0L3lenS540;
    uint32_t _M0L6_2atmpS543;
    uint32_t _M0L6_2atmpS542;
    int32_t _M0L6_2atmpS541;
    uint16_t* _M0L4dataS544;
    int32_t _M0L3lenS549;
    int32_t _M0L6_2atmpS545;
    uint32_t _M0L6_2atmpS548;
    uint32_t _M0L6_2atmpS547;
    int32_t _M0L6_2atmpS546;
    int32_t _M0L3lenS551;
    int32_t _M0L6_2atmpS550;
    #line 105 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
    _M0MPB13StringBuilder19grow__if__necessary(_M0L4selfS109, _M0L6_2atmpS537);
    _M0L4codeS110 = _M0L4codeS107 - 65536u;
    _M0L4dataS539 = _M0L4selfS109->$0;
    _M0L3lenS540 = _M0L4selfS109->$1;
    _M0L6_2atmpS543 = _M0L4codeS110 >> 10;
    _M0L6_2atmpS542 = 55296u + _M0L6_2atmpS543;
    moonbit_incref(_M0L4dataS539);
    #line 107 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
    _M0L6_2atmpS541 = _M0MPC14uint4UInt10to__uint16(_M0L6_2atmpS542);
    if (
      _M0L3lenS540 < 0 || _M0L3lenS540 >= Moonbit_array_length(_M0L4dataS539)
    ) {
      #line 107 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
      moonbit_panic();
    }
    _M0L4dataS539[_M0L3lenS540] = _M0L6_2atmpS541;
    moonbit_decref(_M0L4dataS539);
    _M0L4dataS544 = _M0L4selfS109->$0;
    _M0L3lenS549 = _M0L4selfS109->$1;
    _M0L6_2atmpS545 = _M0L3lenS549 + 1;
    _M0L6_2atmpS548 = _M0L4codeS110 & 1023u;
    _M0L6_2atmpS547 = 56320u + _M0L6_2atmpS548;
    moonbit_incref(_M0L4dataS544);
    #line 108 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
    _M0L6_2atmpS546 = _M0MPC14uint4UInt10to__uint16(_M0L6_2atmpS547);
    if (
      _M0L6_2atmpS545 < 0
      || _M0L6_2atmpS545 >= Moonbit_array_length(_M0L4dataS544)
    ) {
      #line 108 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
      moonbit_panic();
    }
    _M0L4dataS544[_M0L6_2atmpS545] = _M0L6_2atmpS546;
    moonbit_decref(_M0L4dataS544);
    _M0L3lenS551 = _M0L4selfS109->$1;
    _M0L6_2atmpS550 = _M0L3lenS551 + 2;
    _M0L4selfS109->$1 = _M0L6_2atmpS550;
  } else {
    #line 111 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
    _M0FPC15abort5abortGuE((moonbit_string_t)moonbit_string_literal_17.data);
  }
  return 0;
}

int32_t _M0MPB13StringBuilder19grow__if__necessary(
  struct _M0TPB13StringBuilder* _M0L4selfS101,
  int32_t _M0L8requiredS102
) {
  uint16_t* _M0L4dataS529;
  int32_t _M0L12current__lenS100;
  int32_t _M0L13enough__spaceS103;
  int32_t _M0L13enough__spaceS104;
  uint16_t* _M0L4dataS525;
  int32_t _M0L6_2atmpS526;
  int32_t _M0L3lenS527;
  uint16_t* _M0L9new__dataS106;
  uint16_t* _M0L6_2aoldS921;
  #line 46 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L4dataS529 = _M0L4selfS101->$0;
  _M0L12current__lenS100 = Moonbit_array_length(_M0L4dataS529);
  if (_M0L8requiredS102 <= _M0L12current__lenS100) {
    return 0;
  }
  _M0L13enough__spaceS104 = _M0L12current__lenS100;
  while (1) {
    if (_M0L13enough__spaceS104 < _M0L8requiredS102) {
      int32_t _M0L6_2atmpS528 = _M0L13enough__spaceS104 * 2;
      _M0L13enough__spaceS104 = _M0L6_2atmpS528;
      continue;
    } else {
      _M0L13enough__spaceS103 = _M0L13enough__spaceS104;
    }
    break;
  }
  _M0L4dataS525 = _M0L4selfS101->$0;
  moonbit_incref(_M0L4dataS525);
  #line 64 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L6_2atmpS526 = _M0IPC16uint166UInt16PB7Default7default();
  _M0L3lenS527 = _M0L4selfS101->$1;
  #line 61 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L9new__dataS106
  = _M0MPC15array10FixedArray23make__and__blit_2einnerGkE(_M0L4dataS525, _M0L13enough__spaceS103, _M0L6_2atmpS526, _M0L3lenS527, 0, 0);
  moonbit_decref(_M0L4dataS525);
  _M0L6_2aoldS921 = _M0L4selfS101->$0;
  moonbit_decref(_M0L6_2aoldS921);
  _M0L4selfS101->$0 = _M0L9new__dataS106;
  return 0;
}

int32_t _M0MPC14uint4UInt10to__uint16(uint32_t _M0L4selfS99) {
  int32_t _M0L6_2atmpS524;
  #line 2676 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\intrinsics.mbt"
  _M0L6_2atmpS524 = *(int32_t*)&_M0L4selfS99;
  return (uint16_t)_M0L6_2atmpS524;
}

uint32_t _M0MPC14char4Char8to__uint(int32_t _M0L4selfS98) {
  int32_t _M0L6_2atmpS523;
  #line 1254 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\intrinsics.mbt"
  _M0L6_2atmpS523 = _M0L4selfS98;
  return *(uint32_t*)&_M0L6_2atmpS523;
}

moonbit_string_t _M0MPB13StringBuilder10to__string(
  struct _M0TPB13StringBuilder* _M0L4selfS96
) {
  int32_t _M0L3lenS514;
  #line 154 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  _M0L3lenS514 = _M0L4selfS96->$1;
  if (_M0L3lenS514 == 0) {
    return (moonbit_string_t)moonbit_string_literal_0.data;
  } else {
    int32_t _M0L3lenS515 = _M0L4selfS96->$1;
    uint16_t* _M0L4dataS517 = _M0L4selfS96->$0;
    int32_t _M0L6_2atmpS516 = Moonbit_array_length(_M0L4dataS517);
    if (_M0L3lenS515 == _M0L6_2atmpS516) {
      uint16_t* _M0L4dataS518 = _M0L4selfS96->$0;
      moonbit_incref(_M0L4dataS518);
      return _M0L4dataS518;
    } else {
      uint16_t* _M0L4dataS519 = _M0L4selfS96->$0;
      int32_t _M0L3lenS520 = _M0L4selfS96->$1;
      int32_t _M0L6_2atmpS521;
      int32_t _M0L3lenS522;
      uint16_t* _M0L4dataS97;
      moonbit_incref(_M0L4dataS519);
      #line 163 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
      _M0L6_2atmpS521 = _M0IPC16uint166UInt16PB7Default7default();
      _M0L3lenS522 = _M0L4selfS96->$1;
      #line 160 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
      _M0L4dataS97
      = _M0MPC15array10FixedArray23make__and__blit_2einnerGkE(_M0L4dataS519, _M0L3lenS520, _M0L6_2atmpS521, _M0L3lenS522, 0, 0);
      moonbit_decref(_M0L4dataS519);
      return _M0L4dataS97;
    }
  }
}

int32_t _M0IPC16uint166UInt16PB7Default7default() {
  #line 176 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uint16_char.mbt"
  return 0;
}

uint16_t* _M0MPC15array10FixedArray23make__and__blit_2einnerGkE(
  uint16_t* _M0L3srcS93,
  int32_t _M0L13allocate__lenS89,
  int32_t _M0L4initS94,
  int32_t _M0L3lenS90,
  int32_t _M0L11src__offsetS91,
  int32_t _M0L11dst__offsetS92
) {
  int32_t _if__result_997;
  #line 97 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
  if (_M0L13allocate__lenS89 >= 0) {
    if (_M0L3lenS90 >= 0) {
      if (_M0L11src__offsetS91 >= 0) {
        if (_M0L11dst__offsetS92 >= 0) {
          int32_t _M0L6_2atmpS510 = _M0L11src__offsetS91 + _M0L3lenS90;
          int32_t _M0L6_2atmpS511 = Moonbit_array_length(_M0L3srcS93);
          if (_M0L6_2atmpS510 <= _M0L6_2atmpS511) {
            int32_t _M0L6_2atmpS509 = _M0L11dst__offsetS92 + _M0L3lenS90;
            _if__result_997 = _M0L6_2atmpS509 <= _M0L13allocate__lenS89;
          } else {
            _if__result_997 = 0;
          }
        } else {
          _if__result_997 = 0;
        }
      } else {
        _if__result_997 = 0;
      }
    } else {
      _if__result_997 = 0;
    }
  } else {
    _if__result_997 = 0;
  }
  if (_if__result_997) {
    moonbit_incref(_M0L3srcS93);
    #line 115 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    return _M0MPC15array10FixedArray23unsafe__make__and__blitGkE(_M0L3srcS93, _M0L13allocate__lenS89, _M0L4initS94, _M0L11src__offsetS91, _M0L11dst__offsetS92, _M0L3lenS90);
  } else {
    struct _M0TPB13StringBuilder* _M0L18_2astring__builderS95;
    int32_t _M0L6_2atmpS513;
    moonbit_string_t _M0L6_2atmpS512;
    uint16_t* _result_998;
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0L18_2astring__builderS95
    = _M0MPB13StringBuilder21StringBuilder_2einner(89);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS95, (moonbit_string_t)moonbit_string_literal_18.data);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS95, _M0L13allocate__lenS89);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS95, (moonbit_string_t)moonbit_string_literal_19.data);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS95, _M0L11src__offsetS91);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS95, (moonbit_string_t)moonbit_string_literal_20.data);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS95, _M0L11dst__offsetS92);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS95, (moonbit_string_t)moonbit_string_literal_21.data);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS95, _M0L3lenS90);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS95, (moonbit_string_t)moonbit_string_literal_22.data);
    _M0L6_2atmpS513 = Moonbit_array_length(_M0L3srcS93);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS95, _M0L6_2atmpS513);
    #line 112 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _M0L6_2atmpS512
    = _M0MPB13StringBuilder10to__string(_M0L18_2astring__builderS95);
    moonbit_decref(_M0L18_2astring__builderS95);
    #line 111 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
    _result_998 = _M0FPC15abort5abortGAkE(_M0L6_2atmpS512);
    moonbit_decref(_M0L6_2atmpS512);
    return _result_998;
  }
}

uint16_t* _M0MPC15array10FixedArray23unsafe__make__and__blitGkE(
  uint16_t* _M0L3srcS86,
  int32_t _M0L13allocate__lenS83,
  int32_t _M0L4initS84,
  int32_t _M0L11src__offsetS87,
  int32_t _M0L11dst__offsetS85,
  int32_t _M0L9blit__lenS88
) {
  uint16_t* _M0L3dstS82;
  #line 79 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
  _M0L3dstS82
  = (uint16_t*)moonbit_make_string(_M0L13allocate__lenS83, _M0L4initS84);
  moonbit_incref(_M0L3dstS82);
  #line 90 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
  moonbit_unsafe_val_array_blit(_M0L3dstS82, _M0L11dst__offsetS85, _M0L3srcS86, _M0L11src__offsetS87, _M0L9blit__lenS88, sizeof(uint16_t));
  return _M0L3dstS82;
}

struct _M0TPB13StringBuilder* _M0MPB13StringBuilder21StringBuilder_2einner(
  int32_t _M0L10size__hintS80
) {
  int32_t _M0L7initialS79;
  uint16_t* _M0L4dataS81;
  struct _M0TPB13StringBuilder* _block_999;
  #line 32 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder_buffer.mbt"
  if (_M0L10size__hintS80 < 1) {
    _M0L7initialS79 = 1;
  } else {
    int32_t _M0L6_2atmpS508 = _M0L10size__hintS80 + 1;
    _M0L7initialS79 = _M0L6_2atmpS508 / 2;
  }
  _M0L4dataS81 = (uint16_t*)moonbit_make_string(_M0L7initialS79, 0);
  _block_999
  = (struct _M0TPB13StringBuilder*)moonbit_malloc(sizeof(struct _M0TPB13StringBuilder));
  Moonbit_object_header(_block_999)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 30, 0);
  _block_999->$0 = _M0L4dataS81;
  _block_999->$1 = 0;
  return _block_999;
}

int32_t _M0MPC14byte4Byte8to__char(int32_t _M0L4selfS78) {
  int32_t _M0L6_2atmpS507;
  #line 1868 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\intrinsics.mbt"
  _M0L6_2atmpS507 = (int32_t)_M0L4selfS78;
  return _M0L6_2atmpS507;
}

moonbit_string_t* _M0MPB18UninitializedArray23make__and__blit_2einnerGsE(
  moonbit_string_t* _M0L3srcS70,
  int32_t _M0L13allocate__lenS66,
  int32_t _M0L3lenS67,
  int32_t _M0L11src__offsetS68,
  int32_t _M0L11dst__offsetS69
) {
  int32_t _if__result_1000;
  #line 168 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  if (_M0L13allocate__lenS66 >= 0) {
    if (_M0L3lenS67 >= 0) {
      if (_M0L11src__offsetS68 >= 0) {
        if (_M0L11dst__offsetS69 >= 0) {
          int32_t _M0L6_2atmpS498 = _M0L11src__offsetS68 + _M0L3lenS67;
          int32_t _M0L6_2atmpS499;
          #line 179 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
          _M0L6_2atmpS499 = _M0MPB18UninitializedArray6lengthGsE(_M0L3srcS70);
          if (_M0L6_2atmpS498 <= _M0L6_2atmpS499) {
            int32_t _M0L6_2atmpS497 = _M0L11dst__offsetS69 + _M0L3lenS67;
            _if__result_1000 = _M0L6_2atmpS497 <= _M0L13allocate__lenS66;
          } else {
            _if__result_1000 = 0;
          }
        } else {
          _if__result_1000 = 0;
        }
      } else {
        _if__result_1000 = 0;
      }
    } else {
      _if__result_1000 = 0;
    }
  } else {
    _if__result_1000 = 0;
  }
  if (_if__result_1000) {
    moonbit_incref(_M0L3srcS70);
    #line 185 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    return (moonbit_string_t*)moonbit_make_ref_array_with_blit(_M0L13allocate__lenS66, (moonbit_string_t)moonbit_string_literal_0.data, _M0L3srcS70, _M0L11src__offsetS68, _M0L11dst__offsetS69, _M0L3lenS67);
  } else {
    struct _M0TPB13StringBuilder* _M0L18_2astring__builderS71;
    int32_t _M0L6_2atmpS501;
    moonbit_string_t _M0L6_2atmpS500;
    moonbit_string_t* _result_1001;
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0L18_2astring__builderS71
    = _M0MPB13StringBuilder21StringBuilder_2einner(89);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS71, (moonbit_string_t)moonbit_string_literal_18.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS71, _M0L13allocate__lenS66);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS71, (moonbit_string_t)moonbit_string_literal_19.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS71, _M0L11src__offsetS68);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS71, (moonbit_string_t)moonbit_string_literal_20.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS71, _M0L11dst__offsetS69);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS71, (moonbit_string_t)moonbit_string_literal_21.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS71, _M0L3lenS67);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS71, (moonbit_string_t)moonbit_string_literal_22.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0L6_2atmpS501 = _M0MPB18UninitializedArray6lengthGsE(_M0L3srcS70);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS71, _M0L6_2atmpS501);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0L6_2atmpS500
    = _M0MPB13StringBuilder10to__string(_M0L18_2astring__builderS71);
    moonbit_decref(_M0L18_2astring__builderS71);
    #line 181 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _result_1001
    = _M0FPC15abort5abortGRPB18UninitializedArrayGsEE(_M0L6_2atmpS500);
    moonbit_decref(_M0L6_2atmpS500);
    return _result_1001;
  }
}

struct _M0TUsiE** _M0MPB18UninitializedArray23make__and__blit_2einnerGUsiEE(
  struct _M0TUsiE** _M0L3srcS76,
  int32_t _M0L13allocate__lenS72,
  int32_t _M0L3lenS73,
  int32_t _M0L11src__offsetS74,
  int32_t _M0L11dst__offsetS75
) {
  int32_t _if__result_1002;
  #line 168 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  if (_M0L13allocate__lenS72 >= 0) {
    if (_M0L3lenS73 >= 0) {
      if (_M0L11src__offsetS74 >= 0) {
        if (_M0L11dst__offsetS75 >= 0) {
          int32_t _M0L6_2atmpS503 = _M0L11src__offsetS74 + _M0L3lenS73;
          int32_t _M0L6_2atmpS504;
          #line 179 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
          _M0L6_2atmpS504
          = _M0MPB18UninitializedArray6lengthGUsiEE(_M0L3srcS76);
          if (_M0L6_2atmpS503 <= _M0L6_2atmpS504) {
            int32_t _M0L6_2atmpS502 = _M0L11dst__offsetS75 + _M0L3lenS73;
            _if__result_1002 = _M0L6_2atmpS502 <= _M0L13allocate__lenS72;
          } else {
            _if__result_1002 = 0;
          }
        } else {
          _if__result_1002 = 0;
        }
      } else {
        _if__result_1002 = 0;
      }
    } else {
      _if__result_1002 = 0;
    }
  } else {
    _if__result_1002 = 0;
  }
  if (_if__result_1002) {
    moonbit_incref(_M0L3srcS76);
    #line 185 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    return (struct _M0TUsiE**)moonbit_make_ref_array_with_blit(_M0L13allocate__lenS72, 0, _M0L3srcS76, _M0L11src__offsetS74, _M0L11dst__offsetS75, _M0L3lenS73);
  } else {
    struct _M0TPB13StringBuilder* _M0L18_2astring__builderS77;
    int32_t _M0L6_2atmpS506;
    moonbit_string_t _M0L6_2atmpS505;
    struct _M0TUsiE** _result_1003;
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0L18_2astring__builderS77
    = _M0MPB13StringBuilder21StringBuilder_2einner(89);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS77, (moonbit_string_t)moonbit_string_literal_18.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS77, _M0L13allocate__lenS72);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS77, (moonbit_string_t)moonbit_string_literal_19.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS77, _M0L11src__offsetS74);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS77, (moonbit_string_t)moonbit_string_literal_20.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS77, _M0L11dst__offsetS75);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS77, (moonbit_string_t)moonbit_string_literal_21.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS77, _M0L3lenS73);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0IPB13StringBuilderPB6Logger13write__string(_M0L18_2astring__builderS77, (moonbit_string_t)moonbit_string_literal_22.data);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0L6_2atmpS506 = _M0MPB18UninitializedArray6lengthGUsiEE(_M0L3srcS76);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0MPB13StringBuilder13write__objectGiE(_M0L18_2astring__builderS77, _M0L6_2atmpS506);
    #line 182 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _M0L6_2atmpS505
    = _M0MPB13StringBuilder10to__string(_M0L18_2astring__builderS77);
    moonbit_decref(_M0L18_2astring__builderS77);
    #line 181 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
    _result_1003
    = _M0FPC15abort5abortGRPB18UninitializedArrayGUsiEEE(_M0L6_2atmpS505);
    moonbit_decref(_M0L6_2atmpS505);
    return _result_1003;
  }
}

int32_t _M0MPB13StringBuilder13write__objectGsE(
  struct _M0TPB13StringBuilder* _M0L4selfS63,
  moonbit_string_t _M0L3objS62
) {
  struct _M0TPB6Logger _M0L6_2atmpS495;
  #line 17 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder.mbt"
  moonbit_incref(_M0L4selfS63);
  _M0L6_2atmpS495
  = (struct _M0TPB6Logger){
    _M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id,
      _M0L4selfS63
  };
  #line 23 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder.mbt"
  _M0IP016_24default__implPB4Show6outputGsE(_M0L3objS62, _M0L6_2atmpS495);
  if (_M0L6_2atmpS495.$1) {
    moonbit_decref(_M0L6_2atmpS495.$1);
  }
  return 0;
}

int32_t _M0MPB13StringBuilder13write__objectGiE(
  struct _M0TPB13StringBuilder* _M0L4selfS65,
  int32_t _M0L3objS64
) {
  struct _M0TPB6Logger _M0L6_2atmpS496;
  #line 17 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder.mbt"
  moonbit_incref(_M0L4selfS65);
  _M0L6_2atmpS496
  = (struct _M0TPB6Logger){
    _M0FP0119moonbitlang_2fcore_2fbuiltin_2fStringBuilder_2eas___40moonbitlang_2fcore_2fbuiltin_2eLogger_2estatic__method__table__id,
      _M0L4selfS65
  };
  #line 23 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\stringbuilder.mbt"
  _M0IP016_24default__implPB4Show6outputGiE(_M0L3objS64, _M0L6_2atmpS496);
  if (_M0L6_2atmpS496.$1) {
    moonbit_decref(_M0L6_2atmpS496.$1);
  }
  return 0;
}

moonbit_string_t* _M0MPB18UninitializedArray23unsafe__make__and__blitGsE(
  moonbit_string_t* _M0L3srcS53,
  int32_t _M0L13allocate__lenS51,
  int32_t _M0L11src__offsetS54,
  int32_t _M0L11dst__offsetS52,
  int32_t _M0L9blit__lenS55
) {
  moonbit_string_t* _M0L3dstS50;
  #line 133 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  _M0L3dstS50
  = (moonbit_string_t*)moonbit_make_ref_array(_M0L13allocate__lenS51, (moonbit_string_t)moonbit_string_literal_0.data);
  #line 143 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  _M0MPB18UninitializedArray12unsafe__blitGsE(_M0L3dstS50, _M0L11dst__offsetS52, _M0L3srcS53, _M0L11src__offsetS54, _M0L9blit__lenS55);
  moonbit_decref(_M0L3srcS53);
  return _M0L3dstS50;
}

struct _M0TUsiE** _M0MPB18UninitializedArray23unsafe__make__and__blitGUsiEE(
  struct _M0TUsiE** _M0L3srcS59,
  int32_t _M0L13allocate__lenS57,
  int32_t _M0L11src__offsetS60,
  int32_t _M0L11dst__offsetS58,
  int32_t _M0L9blit__lenS61
) {
  struct _M0TUsiE** _M0L3dstS56;
  #line 133 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  _M0L3dstS56
  = (struct _M0TUsiE**)moonbit_make_ref_array(_M0L13allocate__lenS57, 0);
  #line 143 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  _M0MPB18UninitializedArray12unsafe__blitGUsiEE(_M0L3dstS56, _M0L11dst__offsetS58, _M0L3srcS59, _M0L11src__offsetS60, _M0L9blit__lenS61);
  moonbit_decref(_M0L3srcS59);
  return _M0L3dstS56;
}

int32_t _M0MPB18UninitializedArray12unsafe__blitGsE(
  moonbit_string_t* _M0L3dstS40,
  int32_t _M0L11dst__offsetS41,
  moonbit_string_t* _M0L3srcS42,
  int32_t _M0L11src__offsetS43,
  int32_t _M0L3lenS44
) {
  #line 119 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  moonbit_incref(_M0L3srcS42);
  moonbit_incref(_M0L3dstS40);
  #line 128 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  moonbit_unsafe_ref_array_blit(_M0L3dstS40, _M0L11dst__offsetS41, _M0L3srcS42, _M0L11src__offsetS43, _M0L3lenS44);
  return 0;
}

int32_t _M0MPB18UninitializedArray12unsafe__blitGUsiEE(
  struct _M0TUsiE** _M0L3dstS45,
  int32_t _M0L11dst__offsetS46,
  struct _M0TUsiE** _M0L3srcS47,
  int32_t _M0L11src__offsetS48,
  int32_t _M0L3lenS49
) {
  #line 119 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  moonbit_incref(_M0L3srcS47);
  moonbit_incref(_M0L3dstS45);
  #line 128 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  moonbit_unsafe_ref_array_blit(_M0L3dstS45, _M0L11dst__offsetS46, _M0L3srcS47, _M0L11src__offsetS48, _M0L3lenS49);
  return 0;
}

int32_t _M0MPC15array10FixedArray12unsafe__blitGkE(
  uint16_t* _M0L3dstS13,
  int32_t _M0L11dst__offsetS15,
  uint16_t* _M0L3srcS14,
  int32_t _M0L11src__offsetS16,
  int32_t _M0L3lenS18
) {
  int32_t _if__result_1004;
  #line 38 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
  if (_M0L3dstS13 == _M0L3srcS14) {
    _if__result_1004 = _M0L11dst__offsetS15 < _M0L11src__offsetS16;
  } else {
    _if__result_1004 = 0;
  }
  if (_if__result_1004) {
    int32_t _M0L1iS17 = 0;
    while (1) {
      if (_M0L1iS17 < _M0L3lenS18) {
        int32_t _M0L6_2atmpS468 = _M0L11dst__offsetS15 + _M0L1iS17;
        int32_t _M0L6_2atmpS470 = _M0L11src__offsetS16 + _M0L1iS17;
        int32_t _M0L6_2atmpS469;
        int32_t _M0L6_2atmpS471;
        if (
          _M0L6_2atmpS470 < 0
          || _M0L6_2atmpS470 >= Moonbit_array_length(_M0L3srcS14)
        ) {
          #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2atmpS469 = (int32_t)_M0L3srcS14[_M0L6_2atmpS470];
        if (
          _M0L6_2atmpS468 < 0
          || _M0L6_2atmpS468 >= Moonbit_array_length(_M0L3dstS13)
        ) {
          #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L3dstS13[_M0L6_2atmpS468] = _M0L6_2atmpS469;
        _M0L6_2atmpS471 = _M0L1iS17 + 1;
        _M0L1iS17 = _M0L6_2atmpS471;
        continue;
      } else {
        moonbit_decref(_M0L3srcS14);
        moonbit_decref(_M0L3dstS13);
      }
      break;
    }
  } else {
    int32_t _M0L6_2atmpS476 = _M0L3lenS18 - 1;
    int32_t _M0L1iS20 = _M0L6_2atmpS476;
    while (1) {
      if (_M0L1iS20 >= 0) {
        int32_t _M0L6_2atmpS472 = _M0L11dst__offsetS15 + _M0L1iS20;
        int32_t _M0L6_2atmpS474 = _M0L11src__offsetS16 + _M0L1iS20;
        int32_t _M0L6_2atmpS473;
        int32_t _M0L6_2atmpS475;
        if (
          _M0L6_2atmpS474 < 0
          || _M0L6_2atmpS474 >= Moonbit_array_length(_M0L3srcS14)
        ) {
          #line 54 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2atmpS473 = (int32_t)_M0L3srcS14[_M0L6_2atmpS474];
        if (
          _M0L6_2atmpS472 < 0
          || _M0L6_2atmpS472 >= Moonbit_array_length(_M0L3dstS13)
        ) {
          #line 54 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L3dstS13[_M0L6_2atmpS472] = _M0L6_2atmpS473;
        _M0L6_2atmpS475 = _M0L1iS20 - 1;
        _M0L1iS20 = _M0L6_2atmpS475;
        continue;
      } else {
        moonbit_decref(_M0L3srcS14);
        moonbit_decref(_M0L3dstS13);
      }
      break;
    }
  }
  return 0;
}

int32_t _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGsEE(
  moonbit_string_t* _M0L3dstS22,
  int32_t _M0L11dst__offsetS24,
  moonbit_string_t* _M0L3srcS23,
  int32_t _M0L11src__offsetS25,
  int32_t _M0L3lenS27
) {
  int32_t _if__result_1007;
  #line 38 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
  if (_M0L3dstS22 == _M0L3srcS23) {
    _if__result_1007 = _M0L11dst__offsetS24 < _M0L11src__offsetS25;
  } else {
    _if__result_1007 = 0;
  }
  if (_if__result_1007) {
    int32_t _M0L1iS26 = 0;
    while (1) {
      if (_M0L1iS26 < _M0L3lenS27) {
        int32_t _M0L6_2atmpS477 = _M0L11dst__offsetS24 + _M0L1iS26;
        int32_t _M0L6_2atmpS479 = _M0L11src__offsetS25 + _M0L1iS26;
        moonbit_string_t _M0L6_2atmpS478;
        moonbit_string_t _M0L6_2aoldS927;
        int32_t _M0L6_2atmpS480;
        if (
          _M0L6_2atmpS479 < 0
          || _M0L6_2atmpS479 >= Moonbit_array_length(_M0L3srcS23)
        ) {
          #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2atmpS478 = (moonbit_string_t)_M0L3srcS23[_M0L6_2atmpS479];
        if (
          _M0L6_2atmpS477 < 0
          || _M0L6_2atmpS477 >= Moonbit_array_length(_M0L3dstS22)
        ) {
          #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2aoldS927 = (moonbit_string_t)_M0L3dstS22[_M0L6_2atmpS477];
        moonbit_incref(_M0L6_2atmpS478);
        moonbit_decref(_M0L6_2aoldS927);
        _M0L3dstS22[_M0L6_2atmpS477] = _M0L6_2atmpS478;
        _M0L6_2atmpS480 = _M0L1iS26 + 1;
        _M0L1iS26 = _M0L6_2atmpS480;
        continue;
      } else {
        moonbit_decref(_M0L3srcS23);
        moonbit_decref(_M0L3dstS22);
      }
      break;
    }
  } else {
    int32_t _M0L6_2atmpS485 = _M0L3lenS27 - 1;
    int32_t _M0L1iS29 = _M0L6_2atmpS485;
    while (1) {
      if (_M0L1iS29 >= 0) {
        int32_t _M0L6_2atmpS481 = _M0L11dst__offsetS24 + _M0L1iS29;
        int32_t _M0L6_2atmpS483 = _M0L11src__offsetS25 + _M0L1iS29;
        moonbit_string_t _M0L6_2atmpS482;
        moonbit_string_t _M0L6_2aoldS929;
        int32_t _M0L6_2atmpS484;
        if (
          _M0L6_2atmpS483 < 0
          || _M0L6_2atmpS483 >= Moonbit_array_length(_M0L3srcS23)
        ) {
          #line 54 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2atmpS482 = (moonbit_string_t)_M0L3srcS23[_M0L6_2atmpS483];
        if (
          _M0L6_2atmpS481 < 0
          || _M0L6_2atmpS481 >= Moonbit_array_length(_M0L3dstS22)
        ) {
          #line 54 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2aoldS929 = (moonbit_string_t)_M0L3dstS22[_M0L6_2atmpS481];
        moonbit_incref(_M0L6_2atmpS482);
        moonbit_decref(_M0L6_2aoldS929);
        _M0L3dstS22[_M0L6_2atmpS481] = _M0L6_2atmpS482;
        _M0L6_2atmpS484 = _M0L1iS29 - 1;
        _M0L1iS29 = _M0L6_2atmpS484;
        continue;
      } else {
        moonbit_decref(_M0L3srcS23);
        moonbit_decref(_M0L3dstS22);
      }
      break;
    }
  }
  return 0;
}

int32_t _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGUsiEEE(
  struct _M0TUsiE** _M0L3dstS31,
  int32_t _M0L11dst__offsetS33,
  struct _M0TUsiE** _M0L3srcS32,
  int32_t _M0L11src__offsetS34,
  int32_t _M0L3lenS36
) {
  int32_t _if__result_1010;
  #line 38 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
  if (_M0L3dstS31 == _M0L3srcS32) {
    _if__result_1010 = _M0L11dst__offsetS33 < _M0L11src__offsetS34;
  } else {
    _if__result_1010 = 0;
  }
  if (_if__result_1010) {
    int32_t _M0L1iS35 = 0;
    while (1) {
      if (_M0L1iS35 < _M0L3lenS36) {
        int32_t _M0L6_2atmpS486 = _M0L11dst__offsetS33 + _M0L1iS35;
        int32_t _M0L6_2atmpS488 = _M0L11src__offsetS34 + _M0L1iS35;
        struct _M0TUsiE* _M0L6_2atmpS487;
        struct _M0TUsiE* _M0L6_2aoldS931;
        int32_t _M0L6_2atmpS489;
        if (
          _M0L6_2atmpS488 < 0
          || _M0L6_2atmpS488 >= Moonbit_array_length(_M0L3srcS32)
        ) {
          #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2atmpS487 = (struct _M0TUsiE*)_M0L3srcS32[_M0L6_2atmpS488];
        if (
          _M0L6_2atmpS486 < 0
          || _M0L6_2atmpS486 >= Moonbit_array_length(_M0L3dstS31)
        ) {
          #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2aoldS931 = (struct _M0TUsiE*)_M0L3dstS31[_M0L6_2atmpS486];
        if (_M0L6_2atmpS487) {
          moonbit_incref(_M0L6_2atmpS487);
        }
        if (_M0L6_2aoldS931) {
          moonbit_decref(_M0L6_2aoldS931);
        }
        _M0L3dstS31[_M0L6_2atmpS486] = _M0L6_2atmpS487;
        _M0L6_2atmpS489 = _M0L1iS35 + 1;
        _M0L1iS35 = _M0L6_2atmpS489;
        continue;
      } else {
        moonbit_decref(_M0L3srcS32);
        moonbit_decref(_M0L3dstS31);
      }
      break;
    }
  } else {
    int32_t _M0L6_2atmpS494 = _M0L3lenS36 - 1;
    int32_t _M0L1iS38 = _M0L6_2atmpS494;
    while (1) {
      if (_M0L1iS38 >= 0) {
        int32_t _M0L6_2atmpS490 = _M0L11dst__offsetS33 + _M0L1iS38;
        int32_t _M0L6_2atmpS492 = _M0L11src__offsetS34 + _M0L1iS38;
        struct _M0TUsiE* _M0L6_2atmpS491;
        struct _M0TUsiE* _M0L6_2aoldS933;
        int32_t _M0L6_2atmpS493;
        if (
          _M0L6_2atmpS492 < 0
          || _M0L6_2atmpS492 >= Moonbit_array_length(_M0L3srcS32)
        ) {
          #line 54 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2atmpS491 = (struct _M0TUsiE*)_M0L3srcS32[_M0L6_2atmpS492];
        if (
          _M0L6_2atmpS490 < 0
          || _M0L6_2atmpS490 >= Moonbit_array_length(_M0L3dstS31)
        ) {
          #line 54 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\fixedarray_block.mbt"
          moonbit_panic();
        }
        _M0L6_2aoldS933 = (struct _M0TUsiE*)_M0L3dstS31[_M0L6_2atmpS490];
        if (_M0L6_2atmpS491) {
          moonbit_incref(_M0L6_2atmpS491);
        }
        if (_M0L6_2aoldS933) {
          moonbit_decref(_M0L6_2aoldS933);
        }
        _M0L3dstS31[_M0L6_2atmpS490] = _M0L6_2atmpS491;
        _M0L6_2atmpS493 = _M0L1iS38 - 1;
        _M0L1iS38 = _M0L6_2atmpS493;
        continue;
      } else {
        moonbit_decref(_M0L3srcS32);
        moonbit_decref(_M0L3dstS31);
      }
      break;
    }
  }
  return 0;
}

int32_t _M0MPB18UninitializedArray6lengthGsE(moonbit_string_t* _M0L4selfS11) {
  #line 113 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  return Moonbit_array_length(_M0L4selfS11);
}

int32_t _M0MPB18UninitializedArray6lengthGUsiEE(
  struct _M0TUsiE** _M0L4selfS12
) {
  #line 113 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\uninitialized_array.mbt"
  return Moonbit_array_length(_M0L4selfS12);
}

int32_t _M0IPB7FailurePB4Show6output(
  void* _M0L10_2ax__5818S7,
  struct _M0TPB6Logger _M0L10_2ax__5819S10
) {
  struct _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure* _M0L10_2aFailureS8;
  moonbit_string_t _M0L15_2a_2aarg__5820S9;
  #line 37 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\failure.mbt"
  _M0L10_2aFailureS8
  = (struct _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure*)_M0L10_2ax__5818S7;
  _M0L15_2a_2aarg__5820S9 = _M0L10_2aFailureS8->$0;
  #line 37 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\failure.mbt"
  _M0L10_2ax__5819S10.$0->$method_0(_M0L10_2ax__5819S10.$1, (moonbit_string_t)moonbit_string_literal_23.data);
  #line 37 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\failure.mbt"
  _M0MPB6Logger13write__objectGsE(_M0L10_2ax__5819S10, _M0L15_2a_2aarg__5820S9);
  #line 37 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\failure.mbt"
  _M0L10_2ax__5819S10.$0->$method_0(_M0L10_2ax__5819S10.$1, (moonbit_string_t)moonbit_string_literal_24.data);
  return 0;
}

int32_t _M0MPB6Logger13write__objectGsE(
  struct _M0TPB6Logger _M0L4selfS6,
  moonbit_string_t _M0L3objS5
) {
  #line 173 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  #line 174 "C:\\Users\\Administrator\\.moon\\lib\\core\\builtin\\traits.mbt"
  _M0IP016_24default__implPB4Show6outputGsE(_M0L3objS5, _M0L4selfS6);
  return 0;
}

int32_t _M0FPC15abort5abortGuE(moonbit_string_t _M0L3msgS1) {
  #line 47 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  #line 49 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  moonbit_println(_M0L3msgS1);
  #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  moonbit_panic();
  return 0;
}

uint16_t* _M0FPC15abort5abortGAkE(moonbit_string_t _M0L3msgS2) {
  #line 47 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  #line 49 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  moonbit_println(_M0L3msgS2);
  #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  moonbit_panic();
}

moonbit_string_t* _M0FPC15abort5abortGRPB18UninitializedArrayGsEE(
  moonbit_string_t _M0L3msgS3
) {
  #line 47 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  #line 49 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  moonbit_println(_M0L3msgS3);
  #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  moonbit_panic();
}

struct _M0TUsiE** _M0FPC15abort5abortGRPB18UninitializedArrayGUsiEEE(
  moonbit_string_t _M0L3msgS4
) {
  #line 47 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  #line 49 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  moonbit_println(_M0L3msgS4);
  #line 50 "C:\\Users\\Administrator\\.moon\\lib\\core\\abort\\abort.mbt"
  moonbit_panic();
}

moonbit_string_t _M0FP15Error10to__string(void* _M0L4_2aeS439) {
  switch (Moonbit_object_tag(_M0L4_2aeS439)) {
    case 2: {
      return (moonbit_string_t)moonbit_string_literal_25.data;
      break;
    }
    
    case 0: {
      return _M0IP016_24default__implPB4Show10to__stringGRPB7FailureE(_M0L4_2aeS439);
      break;
    }
    
    case 4: {
      return (moonbit_string_t)moonbit_string_literal_26.data;
      break;
    }
    
    case 3: {
      return (moonbit_string_t)moonbit_string_literal_27.data;
      break;
    }
    default: {
      return (moonbit_string_t)moonbit_string_literal_28.data;
      break;
    }
  }
}

int32_t _M0IP016_24default__implPB6Logger61write_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE(
  void* _M0L11_2aobj__ptrS462,
  struct _M0TPB4Show _M0L8_2aparamS461
) {
  struct _M0TPB13StringBuilder* _M0L7_2aselfS460 =
    (struct _M0TPB13StringBuilder*)_M0L11_2aobj__ptrS462;
  _M0IP016_24default__implPB6Logger5writeGRPB13StringBuilderE(_M0L7_2aselfS460, _M0L8_2aparamS461);
  return 0;
}

int32_t _M0IP016_24default__implPB6Logger84write__string__interpolation_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE(
  void* _M0L11_2aobj__ptrS459,
  struct _M0TPB4Show _M0L8_2aparamS458
) {
  struct _M0TPB13StringBuilder* _M0L7_2aselfS457 =
    (struct _M0TPB13StringBuilder*)_M0L11_2aobj__ptrS459;
  _M0IP016_24default__implPB6Logger28write__string__interpolationGRPB13StringBuilderE(_M0L7_2aselfS457, _M0L8_2aparamS458);
  return 0;
}

int32_t _M0IPB13StringBuilderPB6Logger67write__char_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger(
  void* _M0L11_2aobj__ptrS456,
  int32_t _M0L8_2aparamS455
) {
  struct _M0TPB13StringBuilder* _M0L7_2aselfS454 =
    (struct _M0TPB13StringBuilder*)_M0L11_2aobj__ptrS456;
  _M0IPB13StringBuilderPB6Logger11write__char(_M0L7_2aselfS454, _M0L8_2aparamS455);
  return 0;
}

int32_t _M0IPB13StringBuilderPB6Logger67write__view_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger(
  void* _M0L11_2aobj__ptrS453,
  struct _M0TPC16string10StringView _M0L8_2aparamS452
) {
  struct _M0TPB13StringBuilder* _M0L7_2aselfS451 =
    (struct _M0TPB13StringBuilder*)_M0L11_2aobj__ptrS453;
  _M0IPB13StringBuilderPB6Logger11write__view(_M0L7_2aselfS451, _M0L8_2aparamS452);
  return 0;
}

int32_t _M0IP016_24default__implPB6Logger72write__substring_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLoggerGRPB13StringBuilderE(
  void* _M0L11_2aobj__ptrS450,
  moonbit_string_t _M0L8_2aparamS447,
  int32_t _M0L8_2aparamS448,
  int32_t _M0L8_2aparamS449
) {
  struct _M0TPB13StringBuilder* _M0L7_2aselfS446 =
    (struct _M0TPB13StringBuilder*)_M0L11_2aobj__ptrS450;
  _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(_M0L7_2aselfS446, _M0L8_2aparamS447, _M0L8_2aparamS448, _M0L8_2aparamS449);
  return 0;
}

int32_t _M0IPB13StringBuilderPB6Logger69write__string_2edyncall__as___40moonbitlang_2fcore_2fbuiltin_2eLogger(
  void* _M0L11_2aobj__ptrS445,
  moonbit_string_t _M0L8_2aparamS444
) {
  struct _M0TPB13StringBuilder* _M0L7_2aselfS443 =
    (struct _M0TPB13StringBuilder*)_M0L11_2aobj__ptrS445;
  _M0IPB13StringBuilderPB6Logger13write__string(_M0L7_2aselfS443, _M0L8_2aparamS444);
  return 0;
}

void moonbit_init() {
  moonbit_layout_table = moonbit_layout_table_data;
}

int main(int argc, char** argv) {
  struct _M0TWWuEuWRPC15error5ErrorEuEOuQRPC15error5Error** _M0L6_2atmpS467;
  struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE* _M0L12async__testsS433;
  struct _M0TPB5ArrayGUsiEE* _M0L7_2abindS434;
  int32_t _M0L7_2abindS435;
  int32_t _M0L2__S436;
  moonbit_runtime_init(argc, argv);
  moonbit_init();
  _M0L6_2atmpS467
  = (struct _M0TWWuEuWRPC15error5ErrorEuEOuQRPC15error5Error**)moonbit_empty_ref_array;
  _M0L12async__testsS433
  = (struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE*)moonbit_malloc(sizeof(struct _M0TPB5ArrayGVWEuQRPC15error5ErrorE));
  Moonbit_object_header(_M0L12async__testsS433)->meta
  = Moonbit_make_regular_object_header(MOONBIT_REGULAR_LAYOUT_CLASS_INDEXED, 33, 0);
  _M0L12async__testsS433->$0 = _M0L6_2atmpS467;
  _M0L12async__testsS433->$1 = 0;
  #line 437 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0L7_2abindS434
  = _M0FP28re_2dmbt2re52moonbit__test__driver__internal__native__parse__args();
  _M0L7_2abindS435 = _M0L7_2abindS434->$1;
  _M0L2__S436 = 0;
  while (1) {
    if (_M0L2__S436 < _M0L7_2abindS435) {
      struct _M0TUsiE** _M0L3bufS466 = _M0L7_2abindS434->$0;
      struct _M0TUsiE* _M0L3argS437 =
        (struct _M0TUsiE*)_M0L3bufS466[_M0L2__S436];
      moonbit_string_t _M0L6_2atmpS463 = _M0L3argS437->$0;
      int32_t _M0L6_2atmpS464 = _M0L3argS437->$1;
      int32_t _M0L6_2atmpS465;
      moonbit_incref(_M0L6_2atmpS463);
      #line 438 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
      _M0FP28re_2dmbt2re44moonbit__test__driver__internal__do__execute(_M0L12async__testsS433, _M0L6_2atmpS463, _M0L6_2atmpS464);
      moonbit_decref(_M0L6_2atmpS463);
      _M0L6_2atmpS465 = _M0L2__S436 + 1;
      _M0L2__S436 = _M0L6_2atmpS465;
      continue;
    } else {
      moonbit_decref(_M0L7_2abindS434);
    }
    break;
  }
  #line 440 "D:\\CodeWorkspace\\forMoonbit\\re-mbt\\re\\__generated_driver_for_internal_test.mbt"
  _M0IP016_24default__implP28re_2dmbt2re28MoonBit__Async__Test__Driver17run__async__testsGRP28re_2dmbt2re34MoonBit__Async__Test__Driver__ImplE(_M0L12async__testsS433);
  moonbit_decref(_M0L12async__testsS433);
  return 0;
}