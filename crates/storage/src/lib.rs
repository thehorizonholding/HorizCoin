//! Storage backend for HorizCoin.
//!
//! This crate provides a storage abstraction with RocksDB backend and in-memory fallback
//! for the HorizCoin blockchain state management.

use horizcoin_codec::{decode, encode};
use horizcoin_primitives::HorizError;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::path::Path;
use std::sync::{Arc, RwLock};

/// Storage backend trait for key-value operations
pub trait Storage: Send + Sync {
    /// Get a value by key
    fn get(&self, key: &[u8]) -> Result<Option<Vec<u8>>, HorizError>;
    
    /// Put a key-value pair
    fn put(&self, key: &[u8], value: &[u8]) -> Result<(), HorizError>;
    
    /// Delete a key
    fn delete(&self, key: &[u8]) -> Result<(), HorizError>;
    
    /// Check if a key exists
    fn exists(&self, key: &[u8]) -> Result<bool, HorizError>;
    
    /// Get all keys with a given prefix
    fn scan_prefix(&self, prefix: &[u8]) -> Result<Vec<(Vec<u8>, Vec<u8>)>, HorizError>;
    
    /// Get all keys in a range
    fn scan_range(&self, start: &[u8], end: &[u8]) -> Result<Vec<(Vec<u8>, Vec<u8>)>, HorizError>;
    
    /// Create a batch for atomic operations
    fn batch(&self) -> Box<dyn Batch>;
    
    /// Execute a batch atomically
    fn write_batch(&self, batch: Box<dyn Batch>) -> Result<(), HorizError>;
}

/// Batch interface for atomic operations
pub trait Batch: Send {
    /// Add a put operation to the batch
    fn put(&mut self, key: &[u8], value: &[u8]);
    
    /// Add a delete operation to the batch
    fn delete(&mut self, key: &[u8]);
    
    /// Downcast to Any for type checking
    fn as_any(&self) -> &dyn std::any::Any;
    
    /// Downcast to Any for mutable type checking
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any;
}

/// RocksDB storage backend
pub struct RocksDbStorage {
    db: rocksdb::DB,
}

impl RocksDbStorage {
    /// Create a new RocksDB storage at the given path
    pub fn new<P: AsRef<Path>>(path: P) -> Result<Self, HorizError> {
        let mut opts = rocksdb::Options::default();
        opts.create_if_missing(true);
        opts.set_compression_type(rocksdb::DBCompressionType::Lz4);
        
        let db = rocksdb::DB::open(&opts, path)
            .map_err(|e| HorizError::Storage(format!("Failed to open RocksDB: {}", e)))?;
        
        Ok(Self { db })
    }
    
    /// Create a temporary RocksDB storage for testing
    pub fn temp() -> Result<Self, HorizError> {
        let temp_dir = tempfile::tempdir()
            .map_err(|e| HorizError::Storage(format!("Failed to create temp dir: {}", e)))?;
        
        // Keep the temp dir alive by consuming it
        let path = temp_dir.keep();
        Self::new(path)
    }
}

impl Storage for RocksDbStorage {
    fn get(&self, key: &[u8]) -> Result<Option<Vec<u8>>, HorizError> {
        self.db.get(key)
            .map_err(|e| HorizError::Storage(format!("RocksDB get error: {}", e)))
    }
    
    fn put(&self, key: &[u8], value: &[u8]) -> Result<(), HorizError> {
        self.db.put(key, value)
            .map_err(|e| HorizError::Storage(format!("RocksDB put error: {}", e)))
    }
    
    fn delete(&self, key: &[u8]) -> Result<(), HorizError> {
        self.db.delete(key)
            .map_err(|e| HorizError::Storage(format!("RocksDB delete error: {}", e)))
    }
    
    fn exists(&self, key: &[u8]) -> Result<bool, HorizError> {
        Ok(self.get(key)?.is_some())
    }
    
    fn scan_prefix(&self, prefix: &[u8]) -> Result<Vec<(Vec<u8>, Vec<u8>)>, HorizError> {
        let iter = self.db.prefix_iterator(prefix);
        let mut results = Vec::new();
        
        for item in iter {
            let (key, value) = item
                .map_err(|e| HorizError::Storage(format!("RocksDB iterator error: {}", e)))?;
            
            if !key.starts_with(prefix) {
                break;
            }
            
            results.push((key.to_vec(), value.to_vec()));
        }
        
        Ok(results)
    }
    
    fn scan_range(&self, start: &[u8], end: &[u8]) -> Result<Vec<(Vec<u8>, Vec<u8>)>, HorizError> {
        let iter = self.db.iterator(rocksdb::IteratorMode::From(start, rocksdb::Direction::Forward));
        let mut results = Vec::new();
        
        for item in iter {
            let (key, value) = item
                .map_err(|e| HorizError::Storage(format!("RocksDB iterator error: {}", e)))?;
            
            if key.as_ref() >= end {
                break;
            }
            
            results.push((key.to_vec(), value.to_vec()));
        }
        
        Ok(results)
    }
    
    fn batch(&self) -> Box<dyn Batch> {
        Box::new(RocksDbBatch::new())
    }
    
    fn write_batch(&self, mut batch: Box<dyn Batch>) -> Result<(), HorizError> {
        if let Some(rocks_batch) = batch.as_any_mut().downcast_mut::<RocksDbBatch>() {
            let batch_inner = std::mem::replace(&mut rocks_batch.batch, rocksdb::WriteBatch::default());
            self.db.write(batch_inner)
                .map_err(|e| HorizError::Storage(format!("RocksDB batch write error: {}", e)))
        } else {
            Err(HorizError::Storage("Invalid batch type for RocksDB".to_string()))
        }
    }
}

/// RocksDB batch implementation
pub struct RocksDbBatch {
    batch: rocksdb::WriteBatch,
}

impl RocksDbBatch {
    fn new() -> Self {
        Self {
            batch: rocksdb::WriteBatch::default(),
        }
    }
}

impl Batch for RocksDbBatch {
    fn put(&mut self, key: &[u8], value: &[u8]) {
        self.batch.put(key, value);
    }
    
    fn delete(&mut self, key: &[u8]) {
        self.batch.delete(key);
    }
    
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
    
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any {
        self
    }
}

/// In-memory storage backend for testing
#[derive(Clone)]
pub struct MemoryStorage {
    data: Arc<RwLock<BTreeMap<Vec<u8>, Vec<u8>>>>,
}

impl MemoryStorage {
    /// Create a new in-memory storage
    pub fn new() -> Self {
        Self {
            data: Arc::new(RwLock::new(BTreeMap::new())),
        }
    }
}

impl Default for MemoryStorage {
    fn default() -> Self {
        Self::new()
    }
}

impl Storage for MemoryStorage {
    fn get(&self, key: &[u8]) -> Result<Option<Vec<u8>>, HorizError> {
        let data = self.data.read()
            .map_err(|_| HorizError::Storage("Memory storage lock error".to_string()))?;
        Ok(data.get(key).cloned())
    }
    
    fn put(&self, key: &[u8], value: &[u8]) -> Result<(), HorizError> {
        let mut data = self.data.write()
            .map_err(|_| HorizError::Storage("Memory storage lock error".to_string()))?;
        data.insert(key.to_vec(), value.to_vec());
        Ok(())
    }
    
    fn delete(&self, key: &[u8]) -> Result<(), HorizError> {
        let mut data = self.data.write()
            .map_err(|_| HorizError::Storage("Memory storage lock error".to_string()))?;
        data.remove(key);
        Ok(())
    }
    
    fn exists(&self, key: &[u8]) -> Result<bool, HorizError> {
        let data = self.data.read()
            .map_err(|_| HorizError::Storage("Memory storage lock error".to_string()))?;
        Ok(data.contains_key(key))
    }
    
    fn scan_prefix(&self, prefix: &[u8]) -> Result<Vec<(Vec<u8>, Vec<u8>)>, HorizError> {
        let data = self.data.read()
            .map_err(|_| HorizError::Storage("Memory storage lock error".to_string()))?;
        
        let results = data.iter()
            .filter(|(key, _)| key.starts_with(prefix))
            .map(|(key, value)| (key.clone(), value.clone()))
            .collect();
        
        Ok(results)
    }
    
    fn scan_range(&self, start: &[u8], end: &[u8]) -> Result<Vec<(Vec<u8>, Vec<u8>)>, HorizError> {
        let data = self.data.read()
            .map_err(|_| HorizError::Storage("Memory storage lock error".to_string()))?;
        
        let start_bound = std::ops::Bound::Included(start.to_vec());
        let end_bound = std::ops::Bound::Excluded(end.to_vec());
        
        let results = data.range((start_bound, end_bound))
            .map(|(key, value)| (key.clone(), value.clone()))
            .collect();
        
        Ok(results)
    }
    
    fn batch(&self) -> Box<dyn Batch> {
        Box::new(MemoryBatch::new())
    }
    
    fn write_batch(&self, mut batch: Box<dyn Batch>) -> Result<(), HorizError> {
        if let Some(memory_batch) = batch.as_any_mut().downcast_mut::<MemoryBatch>() {
            let mut data = self.data.write()
                .map_err(|_| HorizError::Storage("Memory storage lock error".to_string()))?;
            
            for op in &memory_batch.operations {
                match op {
                    BatchOperation::Put { key, value } => {
                        data.insert(key.clone(), value.clone());
                    }
                    BatchOperation::Delete { key } => {
                        data.remove(key);
                    }
                }
            }
            
            Ok(())
        } else {
            Err(HorizError::Storage("Invalid batch type for MemoryStorage".to_string()))
        }
    }
}

/// Memory batch operations
#[derive(Debug, Clone)]
enum BatchOperation {
    Put { key: Vec<u8>, value: Vec<u8> },
    Delete { key: Vec<u8> },
}

/// Memory batch implementation
struct MemoryBatch {
    operations: Vec<BatchOperation>,
}

impl MemoryBatch {
    fn new() -> Self {
        Self {
            operations: Vec::new(),
        }
    }
}

impl Batch for MemoryBatch {
    fn put(&mut self, key: &[u8], value: &[u8]) {
        self.operations.push(BatchOperation::Put {
            key: key.to_vec(),
            value: value.to_vec(),
        });
    }
    
    fn delete(&mut self, key: &[u8]) {
        self.operations.push(BatchOperation::Delete {
            key: key.to_vec(),
        });
    }
    
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
    
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any {
        self
    }
}

/// Typed storage wrapper for serializable data
pub struct TypedStorage<T> {
    storage: Arc<dyn Storage>,
    _phantom: std::marker::PhantomData<T>,
}

impl<T> TypedStorage<T>
where
    T: Serialize + for<'de> Deserialize<'de>,
{
    /// Create a new typed storage wrapper
    pub fn new(storage: Arc<dyn Storage>) -> Self {
        Self {
            storage,
            _phantom: std::marker::PhantomData,
        }
    }
    
    /// Get a typed value by key
    pub fn get(&self, key: &[u8]) -> Result<Option<T>, HorizError> {
        if let Some(bytes) = self.storage.get(key)? {
            let value = decode(&bytes)?;
            Ok(Some(value))
        } else {
            Ok(None)
        }
    }
    
    /// Put a typed value with key
    pub fn put(&self, key: &[u8], value: &T) -> Result<(), HorizError> {
        let bytes = encode(value)?;
        self.storage.put(key, &bytes)
    }
    
    /// Delete a key
    pub fn delete(&self, key: &[u8]) -> Result<(), HorizError> {
        self.storage.delete(key)
    }
    
    /// Check if a key exists
    pub fn exists(&self, key: &[u8]) -> Result<bool, HorizError> {
        self.storage.exists(key)
    }
    
    /// Scan with prefix and deserialize values
    pub fn scan_prefix(&self, prefix: &[u8]) -> Result<Vec<(Vec<u8>, T)>, HorizError> {
        let items = self.storage.scan_prefix(prefix)?;
        let mut results = Vec::new();
        
        for (key, value_bytes) in items {
            let value = decode(&value_bytes)?;
            results.push((key, value));
        }
        
        Ok(results)
    }
}

impl<T> Clone for TypedStorage<T> {
    fn clone(&self) -> Self {
        Self {
            storage: self.storage.clone(),
            _phantom: std::marker::PhantomData,
        }
    }
}

/// Storage factory for creating different storage backends
pub struct StorageFactory;

impl StorageFactory {
    /// Create a RocksDB storage backend
    pub fn rocksdb<P: AsRef<Path>>(path: P) -> Result<Arc<dyn Storage>, HorizError> {
        Ok(Arc::new(RocksDbStorage::new(path)?))
    }
    
    /// Create a temporary RocksDB storage for testing
    pub fn temp_rocksdb() -> Result<Arc<dyn Storage>, HorizError> {
        Ok(Arc::new(RocksDbStorage::temp()?))
    }
    
    /// Create an in-memory storage backend
    pub fn memory() -> Arc<dyn Storage> {
        Arc::new(MemoryStorage::new())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_memory_storage_basic_operations() {
        let storage = MemoryStorage::new();
        
        // Test put and get
        storage.put(b"key1", b"value1").unwrap();
        assert_eq!(storage.get(b"key1").unwrap(), Some(b"value1".to_vec()));
        
        // Test exists
        assert!(storage.exists(b"key1").unwrap());
        assert!(!storage.exists(b"nonexistent").unwrap());
        
        // Test delete
        storage.delete(b"key1").unwrap();
        assert_eq!(storage.get(b"key1").unwrap(), None);
    }

    #[test]
    fn test_memory_storage_prefix_scan() {
        let storage = MemoryStorage::new();
        
        storage.put(b"prefix:key1", b"value1").unwrap();
        storage.put(b"prefix:key2", b"value2").unwrap();
        storage.put(b"other:key3", b"value3").unwrap();
        
        let results = storage.scan_prefix(b"prefix:").unwrap();
        assert_eq!(results.len(), 2);
        
        let keys: Vec<_> = results.iter().map(|(k, _)| k.clone()).collect();
        assert!(keys.contains(&b"prefix:key1".to_vec()));
        assert!(keys.contains(&b"prefix:key2".to_vec()));
    }

    #[test]
    fn test_memory_storage_range_scan() {
        let storage = MemoryStorage::new();
        
        storage.put(b"a", b"value_a").unwrap();
        storage.put(b"b", b"value_b").unwrap();
        storage.put(b"c", b"value_c").unwrap();
        storage.put(b"d", b"value_d").unwrap();
        
        let results = storage.scan_range(b"b", b"d").unwrap();
        assert_eq!(results.len(), 2);
        
        let keys: Vec<_> = results.iter().map(|(k, _)| k.clone()).collect();
        assert!(keys.contains(&b"b".to_vec()));
        assert!(keys.contains(&b"c".to_vec()));
    }

    #[test]
    fn test_memory_storage_batch() {
        let storage = MemoryStorage::new();
        
        let mut batch = storage.batch();
        batch.put(b"batch_key1", b"batch_value1");
        batch.put(b"batch_key2", b"batch_value2");
        batch.delete(b"nonexistent");
        
        storage.write_batch(batch).unwrap();
        
        assert_eq!(storage.get(b"batch_key1").unwrap(), Some(b"batch_value1".to_vec()));
        assert_eq!(storage.get(b"batch_key2").unwrap(), Some(b"batch_value2".to_vec()));
    }

    #[test]
    fn test_rocksdb_storage_basic_operations() {
        let storage = RocksDbStorage::temp().unwrap();
        
        // Test put and get
        storage.put(b"key1", b"value1").unwrap();
        assert_eq!(storage.get(b"key1").unwrap(), Some(b"value1".to_vec()));
        
        // Test exists
        assert!(storage.exists(b"key1").unwrap());
        assert!(!storage.exists(b"nonexistent").unwrap());
        
        // Test delete
        storage.delete(b"key1").unwrap();
        assert_eq!(storage.get(b"key1").unwrap(), None);
    }

    #[test]
    fn test_typed_storage() {
        use serde::{Deserialize, Serialize};
        
        #[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
        struct TestData {
            id: u64,
            name: String,
        }
        
        let storage = StorageFactory::memory();
        let typed_storage = TypedStorage::<TestData>::new(storage);
        
        let data = TestData {
            id: 123,
            name: "test".to_string(),
        };
        
        typed_storage.put(b"test_key", &data).unwrap();
        let retrieved = typed_storage.get(b"test_key").unwrap().unwrap();
        
        assert_eq!(data, retrieved);
    }

    #[test]
    fn test_storage_factory() {
        // Test memory storage creation
        let memory_storage = StorageFactory::memory();
        memory_storage.put(b"test", b"value").unwrap();
        assert_eq!(memory_storage.get(b"test").unwrap(), Some(b"value".to_vec()));
        
        // Test temp RocksDB storage creation
        let rocks_storage = StorageFactory::temp_rocksdb().unwrap();
        rocks_storage.put(b"test", b"value").unwrap();
        assert_eq!(rocks_storage.get(b"test").unwrap(), Some(b"value".to_vec()));
    }

    #[test]
    fn test_concurrent_access() {
        use std::thread;
        
        let storage = Arc::new(MemoryStorage::new());
        let mut handles = Vec::new();
        
        // Spawn multiple threads to test concurrent access
        for i in 0..10 {
            let storage_clone = storage.clone();
            let handle = thread::spawn(move || {
                let key = format!("key{}", i).into_bytes();
                let value = format!("value{}", i).into_bytes();
                
                storage_clone.put(&key, &value).unwrap();
                let result = storage_clone.get(&key).unwrap();
                
                assert_eq!(result, Some(value));
            });
            handles.push(handle);
        }
        
        for handle in handles {
            handle.join().unwrap();
        }
        
        // Verify all data was written
        for i in 0..10 {
            let key = format!("key{}", i).into_bytes();
            let expected_value = format!("value{}", i).into_bytes();
            assert_eq!(storage.get(&key).unwrap(), Some(expected_value));
        }
    }
}
