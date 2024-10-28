import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Array "mo:base/Array";

module {
  public type CacheStats = {
    hits: Nat;
    misses: Nat;
    evictions: Nat;
    currentSize: Nat;
    capacity: Nat;
  };

  private let MAX_CACHE_SIZE: Nat = 10_000;

  private type Node<K, V> = {
    key: K;
    var value: V;
    var prev: ?Node<K, V>;
    var next: ?Node<K, V>;
  };

  public class LRU<K, V>(initCap: Nat, equal: (K, K) -> Bool, hash: K -> Hash.Hash) {
    private var cap: Nat = Nat.min(initCap, MAX_CACHE_SIZE);
    private var head: ?Node<K, V> = null;
    private var tail: ?Node<K, V> = null;
    private var cache = HashMap.HashMap<K, Node<K, V>>(cap, equal, hash);
    private var hits: Nat = 0;
    private var misses: Nat = 0;
    private var evictions: Nat = 0;
    private var evictionCallback: ?((K, V) -> ()) = null;

    public func get(key: K, callback: ?((K, V) -> ?V)): ?V {
      switch (cache.get(key)) {
        case (?node) {
          moveToFront(node);
          hits += 1;
          switch (callback) {
            case (?cb) {
              switch (cb(node.key, node.value)) {
                case (?newVal) {
                  node.value := newVal;
                  ?newVal
                };
                case null { ?node.value };
              };
            };
            case null { ?node.value };
          };
        };
        case null {
          misses += 1;
          null
        };
      };
    };

    public func put(key: K, value: V) {
      assert(cap > 0);
      
      switch (cache.get(key)) {
        case (?node) {
          node.value := value;
          moveToFront(node);
        };
        case null {
          if (cache.size() >= cap) { evict() };
          let newNode = {
            key = key;
            var value = value;
            var prev = null : ?Node<K, V>;
            var next = null : ?Node<K, V>;
          };
          addToFront(newNode);
          cache.put(key, newNode);
        };
      };
      assert(cache.size() <= cap);
    };

    private func moveToFront(node: Node<K, V>) {
      switch (node.prev) {
        case (?prev) { prev.next := node.next };
        case null { return};
      };

      switch (node.next) {
        case (?next) { next.prev := node.prev };
        case null { tail := node.prev };
      };
      addToFront(node);
    };

    private func addToFront(node: Node<K, V>) {
      node.prev := null;
      node.next := head;
      switch (head) {
        case (?h) { h.prev := ?node };
        case null { tail := ?node };
      };
      head := ?node;
    };

    public func evict() {
      switch (tail) {
        case (?t) {
          cache.delete(t.key);
          switch (t.prev) {
            case (?prev) {
              prev.next := null;
              tail := ?prev;
            };
            case null {
              head := null;
              tail := null;
            };
          };
          switch (evictionCallback) {
            case (?cb) { cb(t.key, t.value) };
            case null {};
          };
          evictions += 1;
        };
        case null {};
      };
    };

    public func setEvictionCallback(callback: ?((K, V) -> ())) {
      evictionCallback := callback;
    };

    public func size(): Nat {
      cache.size()
    };

    public func putAll(entries: Iter.Iter<(K, V)>) {
      for ((key, value) in entries) {
        put(key, value);
      };
    };

    public func stats(): CacheStats {
      {
        hits = hits;
        misses = misses;
        evictions = evictions;
        currentSize = cache.size();
        capacity = cap;
      }
    };

    public func resize(newCap: Nat) {
      assert(newCap > 0 and newCap <= MAX_CACHE_SIZE);
      if (newCap == cap) return;
      cap := newCap;
      let oldCache = cache;
      cache := HashMap.HashMap<K, Node<K, V>>(newCap, equal, hash);
      head := null;
      tail := null;
      label l for ((key, node) in oldCache.entries()) {
        if (cache.size() < cap) {
          put(key, node.value);
        } else {
          break l;
        };
      };
    };
    public func showCache(): [V] {
    var result: [V] = [];
    var current = head;

    while (switch (current) {
      case (?node) {
        result := Array.append(result, [node.value]);
        current := node.next;
        true;
      };
      case null { false };
      }) {};
    return result;
    };


    public func clear() {
      cache := HashMap.HashMap<K, Node<K, V>>(cap, equal, hash);
      head := null;
      tail := null;
      hits := 0;
      misses := 0;
      evictions := 0;
    };

    public func toIter(): Iter.Iter<(K, V)> {
      object {
        var current = head;
        public func next(): ?(K, V) {
          switch (current) {
            case (?node) {
              current := node.next;
              ?(node.key, node.value)
            };
            case null { null };
          }
        };
      }
    };
  };
};
