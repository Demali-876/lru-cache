import LRU "../lib";
import Text "mo:base/Text";

actor {
  public func runExample() :async [Text]{

    // Create an LRU cache with space for 3 recipes
    //You must provide your own equality and hash functions
    let cache = LRU.LRU<Text, Text>(3, Text.equal, Text.hash);

    // First request: Chocolate Cake
    cache.put("recipe1", "Chocolate Cake");
    //Cache : [Chocolate Cake]

    // Second request: Vanilla Cake
    cache.put("recipe2", "Vanilla Cake");
    //Cache : [Vanilla Cake, Chocolate Cake]

    // Third request: Strawberry Cake
    cache.put("recipe3", "Strawberry Cake");
    //Cache : [Strawberry Cake, Vanilla Cake, Chocolate Cake]

    // Fourth request: Chocolate Cake (again)
    ignore cache.get("recipe1", null); // null means no callback
    //Cache : [Chocolate Cake, Strawberry Cake, Vanilla Cake]

    cache.put("recipe4", "Pound Cake");
    //Cache : [Pound Cake,Chocolate Cake, Strawberry Cake]
    
    cache.showCache();
    // [Pound Cake, Chocolate Cake, Strawberry Cake]
  };
};

