// Cache — memoization for compiled regexes.
// 同一 (pattern, opts) 重复编译时命中缓存，返回 copy_re 副本（独立 tbl / initial_states），
// 避免调用方共享可变 WorkingArea。MoonBit 当前后端单线程，无需加锁。

///|
/// ReCache — 编译缓存。key 为模式字节 + opts 编码（由前端构造），value 为已编译 Re。
/// English: Compilation cache. Key = pattern bytes + opts encoding (built by frontends);
/// value = compiled Re. Hits return copy_re clones with independent WorkingArea.
pub struct ReCache {
  cache : @hashmap.HashMap[Bytes, Re]
}

///|
/// 创建空缓存。English: Create an empty cache.
pub fn ReCache::new() -> ReCache {
  { cache: @hashmap.HashMap::HashMap([]), }
}

///|
/// 创建指定初始容量的空缓存。English: Create an empty cache with given capacity.
pub fn ReCache::new_with_capacity(capacity : Int32) -> ReCache {
  { cache: @hashmap.HashMap::HashMap([], capacity~), }
}

///|
/// 查缓存编译：命中返回 copy_re 副本，未命中编译并缓存原值后返回。
/// English: Lookup-or-compile: on hit return a copy_re clone; on miss compile, cache, return.
pub fn ReCache::compile(
  self : ReCache,
  key : Bytes,
  ast : @ast.AstGen[@ast.AstCset],
) -> Re {
  match self.cache.get(key) {
    Some(re) => copy_re(re)
    None => {
      let re = compile(ast)
      self.cache[key] = re
      re
    }
  }
}

///|
/// 仅查缓存：命中返回 copy_re 副本，未命中返回 None。
/// English: Lookup only: on hit return a copy_re clone; on miss return None.
pub fn ReCache::get(self : ReCache, key : Bytes) -> Re? {
  match self.cache.get(key) {
    Some(re) => Some(copy_re(re))
    None => None
  }
}

///|
/// 缓存条目数。English: Number of cached entries.
pub fn ReCache::length(self : ReCache) -> Int32 {
  self.cache.length()
}

///|
/// 清空缓存。English: Clear all cached entries.
pub fn ReCache::clear(self : ReCache) -> Unit {
  self.cache.clear()
}
